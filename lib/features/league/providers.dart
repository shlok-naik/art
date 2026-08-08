import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../auth/providers.dart';
import '../profile/providers.dart';
import '../projects/providers.dart';
import 'data/league_repository.dart';
import 'domain/league.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepository(ref.watch(supabaseClientProvider));
});

/// The current weekly league — materialized lazily server-side by the
/// `get_or_create_current_league()` Postgres function the first time anyone
/// asks, so this is safe to watch from app start with no separate "is there
/// a league yet?" check.
final currentLeagueProvider = FutureProvider.autoDispose<League>((ref) {
  return ref.watch(leagueRepositoryProvider).fetchCurrentLeague();
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

/// The winning entry from the most recently ended league, if any.
final latestLeagueChampionProvider = FutureProvider.autoDispose<LeagueChampion?>((ref) {
  return ref.watch(leagueRepositoryProvider).fetchLatestChampion();
});

/// Every league [userId] has won, most recent first — works for any
/// profile, so a visitor's public profile can show a real trophy cabinet
/// too, not just the owner's.
final myLeagueTrophiesProvider = FutureProvider.autoDispose.family<List<LeagueTrophy>, String>((ref, userId) {
  return ref.watch(leagueRepositoryProvider).fetchTrophies(userId);
});

/// League ids already celebrated (had their confetti screen shown) this app
/// session — guards against the same race [celebratedAchievementKeysProvider]
/// guards against: two near-simultaneous evaluations of
/// [newlyWonTrophiesProvider] both reading `league_trophy_celebrations`
/// before either write lands, both concluding the same trophy is new.
final celebratedTrophyLeagueIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Trophies the signed-in user has won but hasn't seen the celebration
/// screen for yet — computing this value marks them seen (persists a row
/// per newly-found trophy) as a side effect, then returns just the ones
/// that were new, for the UI to celebrate. Same shape as
/// [newlyUnlockedAchievementsProvider]; the difference is a trophy is
/// "won" by other people's votes and the passage of time rather than by
/// anything the client computes, so there's no unlock condition to
/// evaluate — only "have we marked this one seen yet".
final newlyWonTrophiesProvider = FutureProvider.autoDispose<List<LeagueTrophy>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return const [];
  final userId = profile.id;

  final repo = ref.watch(leagueRepositoryProvider);
  final trophies = await repo.fetchTrophies(userId);
  if (trophies.isEmpty) return const [];

  final celebrated = await repo.fetchCelebratedTrophyLeagueIds(userId);
  final newlyWon = <LeagueTrophy>[];
  for (final trophy in trophies) {
    if (!celebrated.contains(trophy.leagueId)) {
      await repo.markTrophyCelebrated(userId: userId, leagueId: trophy.leagueId);
      newlyWon.add(trophy);
    }
  }
  if (newlyWon.isNotEmpty) {
    ref.invalidate(myLeagueTrophiesProvider(userId));
  }
  return newlyWon;
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

  // fetchSessionsForProjects orders newest-first, so the first photo seen
  // per project is its most recent one.
  final coverByProjectId = <String, String>{};
  for (final session in sessions) {
    final projectId = session['project_id']?.toString();
    final photoUrl = session['photo_url']?.toString();
    if (projectId == null || photoUrl == null || photoUrl.isEmpty) continue;
    coverByProjectId.putIfAbsent(projectId, () => photoUrl);
  }

  return [
    for (final project in projects)
      if (coverByProjectId[project['id'].toString()] case final cover?) (project, cover),
  ];
});
