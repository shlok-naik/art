import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../projects/providers.dart';
import 'data/follows_repository.dart';
import 'data/profile_model.dart';
import 'data/profile_repository.dart';
import 'data/stats_repository.dart';
import 'domain/project_gallery.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final followsRepositoryProvider = Provider<FollowsRepository>((ref) {
  return FollowsRepository(ref.watch(supabaseClientProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(supabaseClientProvider));
});

final currentProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value?.session?.user;
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(user.id);
});

/// Any profile by id — used by the public profile screen, unlike
/// [currentProfileProvider] which is pinned to the signed-in user.
final profileByIdProvider = FutureProvider.autoDispose.family<Profile?, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});

/// Follower/following counts for a given profile id.
final followCountsProvider =
    FutureProvider.autoDispose.family<({int followers, int following}), String>((ref, userId) {
  return ref.watch(followsRepositoryProvider).fetchFollowCounts(userId);
});

/// Whether the signed-in user follows [userId].
final isFollowingProvider = FutureProvider.autoDispose.family<bool, String>((ref, userId) {
  return ref.watch(followsRepositoryProvider).isFollowing(userId);
});

/// Profiles the signed-in user follows.
final followingListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(followsRepositoryProvider).fetchFollowing();
});

/// Profiles the signed-in user doesn't yet follow, for "Suggested artists".
final suggestedArtistsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(followsRepositoryProvider).fetchSuggested();
});

/// People the signed-in user follows who also follow [userId] — drives the
/// "Followed by X, Y and N others" line on a profile.
final mutualFollowersProvider = FutureProvider.autoDispose
    .family<({List<Map<String, dynamic>> profiles, int totalCount}), String>((ref, userId) {
  return ref.watch(followsRepositoryProvider).fetchMutualFollowers(userId);
});

/// Time-spent/session-count/streak/difficulty/work-style aggregates for a
/// given user's Stats page.
final sessionStatsProvider = FutureProvider.autoDispose.family<SessionStats, String>((ref, userId) {
  return ref.watch(statsRepositoryProvider).fetchSessionStats(userId);
});

/// Project-count/finished-count aggregates for a given user's Stats page.
final projectStatsProvider = FutureProvider.autoDispose.family<ProjectStats, String>((ref, userId) {
  return ref.watch(statsRepositoryProvider).fetchProjectStats(userId);
});

/// Per-stage time totals for a given user's "Time per stage" chart.
final stageMinutesProvider = FutureProvider.autoDispose.family<List<StageMinutes>, String>((ref, userId) {
  return ref.watch(statsRepositoryProvider).fetchStageMinutes(userId);
});

/// Session count per difficulty rating for a given user's "Difficulty
/// spread" chart.
final difficultyHistogramProvider = FutureProvider.autoDispose.family<List<int>, String>((ref, userId) {
  return ref.watch(statsRepositoryProvider).fetchDifficultyHistogram(userId);
});

/// A user's projects paired with their photographed sessions, for the
/// "Projects" circles row on a profile. Only projects with at least one
/// photographed session are included — an empty circle has nothing to
/// preview or open.
final userProjectGalleriesProvider =
    FutureProvider.autoDispose.family<List<ProjectGallery>, String>((ref, userId) async {
  final projects = await ref.watch(projectsRepositoryProvider).fetchProjectsByUser(userId);
  if (projects.isEmpty) return const [];

  final projectIds = [for (final project in projects) project['id'].toString()];
  final sessions = await ref.watch(sessionsRepositoryProvider).fetchSessionsForProjects(projectIds);

  final sessionsByProject = <String, List<Map<String, dynamic>>>{};
  for (final session in sessions) {
    final photoUrl = session['photo_url']?.toString();
    if (photoUrl == null || photoUrl.isEmpty) continue;
    sessionsByProject.putIfAbsent(session['project_id'].toString(), () => []).add(session);
  }

  return [
    for (final project in projects)
      if (sessionsByProject[project['id'].toString()] case final projectSessions?)
        ProjectGallery(project: project, sessions: projectSessions),
  ];
});
