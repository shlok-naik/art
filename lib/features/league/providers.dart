import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../profile/providers.dart';
import '../projects/providers.dart';
import 'data/league_chat_repository.dart';
import 'data/league_repository.dart';
import 'domain/league.dart';
import 'domain/league_chat_message.dart';
import 'domain/league_city.dart';
import 'domain/project_cover.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepository(ref.watch(supabaseClientProvider));
});

final leagueChatRepositoryProvider = Provider<LeagueChatRepository>((ref) {
  return LeagueChatRepository(ref.watch(supabaseClientProvider));
});

/// The current weekly league for the signed-in user's city — materialized
/// lazily server-side by the `get_or_create_current_league()` Postgres
/// function the first time anyone in that city asks, so this is safe to
/// watch from app start with no separate "is there a league yet?" check.
///
/// Throws [NoCitySelectedException] if the signed-in user hasn't picked a
/// city yet, so [LeagueScreen] can show a picker instead of an error —
/// consumers that only need `.value` (e.g. [leagueRankProvider]'s callers)
/// naturally see null in that case rather than crashing.
final currentLeagueProvider = FutureProvider.autoDispose<League>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  final city = profile?.city;
  if (city == null) throw const NoCitySelectedException();
  return ref.watch(leagueRepositoryProvider).fetchCurrentLeague(city);
});

/// Submissions for [leagueId], highest-voted first.
final leagueSubmissionsProvider =
    FutureProvider.autoDispose.family<List<LeagueSubmission>, String>((ref, leagueId) {
  return ref.watch(leagueRepositoryProvider).fetchSubmissions(leagueId);
});

/// The signed-in user's ratings in [leagueId], keyed by submission id.
final myLeagueRatingsProvider = FutureProvider.autoDispose.family<Map<String, int>, String>((ref, leagueId) {
  return ref.watch(leagueRepositoryProvider).fetchMyRatings(leagueId);
});

/// [userId]'s current standing in this week's league — 1-based rank of
/// their best submission, or null if they haven't submitted. Used by the
/// profile and stats screens so "League rank" shows the same live value the
/// league leaderboard does.
final leagueRankProvider = FutureProvider.autoDispose.family<int?, String>((ref, userId) async {
  final league = await ref.watch(currentLeagueProvider.future);
  final submissions = await ref.watch(leagueSubmissionsProvider(league.id).future);
  // fetchSubmissions orders by stars descending, so the first index where
  // the user appears is their best submission's rank.
  final index = submissions.indexWhere((submission) => submission.userId == userId);
  return index < 0 ? null : index + 1;
});

/// The winning entry from the most recently ended league the signed-in user
/// was a member of, if any — null (rather than throwing) when no city is
/// picked yet, since this card is decorative and shouldn't block the rest
/// of the league screen the way [currentLeagueProvider] does. Matched
/// server-side by league membership rather than city, since a city can be
/// split across multiple capacity-capped league shards (see
/// `latest_league_champion()` in reset_schema.sql).
final latestLeagueChampionProvider = FutureProvider.autoDispose<LeagueChampion?>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.city == null) return null;
  return ref.watch(leagueRepositoryProvider).fetchLatestChampion();
});

/// Every league [userId] has won, most recent first — works for any
/// profile, so a visitor's public profile can show a real trophy cabinet
/// too, not just the owner's.
final myLeagueTrophiesProvider = FutureProvider.autoDispose.family<List<LeagueTrophy>, String>((ref, userId) {
  return ref.watch(leagueRepositoryProvider).fetchTrophies(userId);
});

/// Trophies the signed-in user has won but hasn't seen the celebration
/// screen for yet — computing this value atomically claims them (a single
/// insert-and-return call to `claim_newly_won_trophies()`, which persists a
/// row per newly-found trophy in `league_trophy_celebrations`), then returns
/// just the ones that were new, for the UI to celebrate. Same shape as
/// [newlyUnlockedAchievementsProvider]; the difference is a trophy is "won"
/// by other people's votes and the passage of time rather than by anything
/// the client computes, so there's no unlock condition to evaluate — only
/// "have we marked this one seen yet". Persisted server-side (rather than
/// on-device) so the celebration doesn't replay on a different device or
/// after a reinstall, and claimed atomically server-side so a Riverpod
/// rebuild racing an earlier call can't double-fire the celebration.
final newlyWonTrophiesProvider = FutureProvider.autoDispose<List<LeagueTrophy>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return const [];
  return ref.watch(leagueRepositoryProvider).claimNewlyWonTrophies();
});

/// The signed-in user's projects that have at least one session photo,
/// paired with that project's most recent photo as its cover — the picker
/// grid for submitting a project to a league. Projects with no sessions (or
/// no session photo yet) are excluded, same as the old "posts with a photo"
/// filter this replaced.
final myProjectsWithCoverProvider =
    FutureProvider.autoDispose<List<(Map<String, dynamic> project, String coverPhotoUrl)>>((ref) async {
  final projects = await ref.watch(projectsListProvider.future);
  final projectIds = [for (final project in projects) project['id'].toString()];
  final sessions = await ref.watch(sessionsRepositoryProvider).fetchSessionsForProjects(projectIds);
  return projectsWithCoverPhotos(projects: projects, sessions: sessions);
});

/// Chat messages for [leagueId], oldest first, kept live by a realtime
/// subscription — the app's first realtime feature. [build] fetches history
/// once, then opens a channel that appends each new message as it's
/// inserted, so every open League Chat screen updates without polling or a
/// pull-to-refresh.
final leagueChatMessagesProvider = AsyncNotifierProvider.autoDispose
    .family<LeagueChatNotifier, List<LeagueChatMessage>, String>(LeagueChatNotifier.new);

class LeagueChatNotifier extends AsyncNotifier<List<LeagueChatMessage>> {
  LeagueChatNotifier(this._leagueId);

  final String _leagueId;

  @override
  Future<List<LeagueChatMessage>> build() async {
    final repo = ref.watch(leagueChatRepositoryProvider);
    final messages = await repo.fetchMessages(_leagueId);

    final channel = repo.subscribeToNewMessages(_leagueId, _handleInsert);
    ref.onDispose(() => channel.unsubscribe());

    return messages;
  }

  final _knownUsernames = <String, String>{};

  Future<void> _handleInsert(Map<String, dynamic> row) async {
    final current = state.value;
    if (current == null) return;
    final id = row['id'].toString();
    // Already have it — either it's our own optimistic send echoing back, or
    // a duplicate delivery.
    if (current.any((m) => m.id == id)) return;

    final userId = row['user_id'].toString();
    var username = _knownUsernames[userId];
    if (username == null) {
      username = await ref.read(leagueChatRepositoryProvider).fetchUsername(userId);
      _knownUsernames[userId] = username;
    }

    final latest = state.value;
    if (latest == null || latest.any((m) => m.id == id)) return;
    state = AsyncData([...latest, LeagueChatMessage.fromRow(row, username: username)]);
  }

  /// Moderates and sends [body], appending it locally right away — the
  /// realtime echo of our own insert is deduped against this by id in
  /// [_handleInsert].
  Future<void> send(String body) async {
    final profile = await ref.read(currentProfileProvider.future);
    if (profile == null) throw Exception('Not signed in');
    _knownUsernames[profile.id] = profile.username;

    final repo = ref.read(leagueChatRepositoryProvider);
    final row = await repo.sendMessage(leagueId: _leagueId, body: body);

    final current = state.value;
    if (current == null) return;
    final id = row['id'].toString();
    if (current.any((m) => m.id == id)) return;
    state = AsyncData([...current, LeagueChatMessage.fromRow(row, username: profile.username)]);
  }

  Future<void> delete(String messageId) async {
    await ref.read(leagueChatRepositoryProvider).deleteMessage(messageId);
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.where((m) => m.id != messageId).toList());
  }

  Future<void> report(String messageId) {
    return ref.read(leagueChatRepositoryProvider).reportMessage(messageId);
  }
}
