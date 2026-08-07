import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../projects/providers.dart';
import 'data/league_repository.dart';
import 'domain/league.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  return LeagueRepository(ref.watch(supabaseClientProvider));
});

/// The current 2-week league — materialized lazily server-side the first
/// time anyone asks (see get_or_create_current_league() in
/// add_league_tables.sql), so this is safe to watch from app start with no
/// separate "is there a league yet?" check.
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
