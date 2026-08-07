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

/// The submission id the signed-in user has voted for in [leagueId], or
/// null if they haven't voted yet.
final myLeagueVoteProvider = FutureProvider.autoDispose.family<String?, String>((ref, leagueId) {
  return ref.watch(leagueRepositoryProvider).fetchMyVote(leagueId);
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
