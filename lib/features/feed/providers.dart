import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/providers.dart';
import '../projects/providers.dart';
import 'domain/feed_post.dart';

String _formatTimeTaken(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  return '${minutes}m';
}

/// Builds the feed from the current user's real projects and sessions,
/// newest first. Each session with a photo becomes one feed post.
final feedPostsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) async {
  final projectsRepo = ref.watch(projectsRepositoryProvider);
  final sessionsRepo = ref.watch(sessionsRepositoryProvider);
  final username = ref.watch(currentProfileProvider).value?.username ?? 'you';

  final projects = await projectsRepo.fetchProjects();
  final posts = <FeedPost>[];

  for (final project in projects) {
    final projectId = project['id'].toString();
    final projectTitle = project['title']?.toString() ?? projectId;
    final sessions = await sessionsRepo.fetchSessions(projectId);

    for (final session in sessions) {
      final photoUrl = session['photo_url']?.toString();
      if (photoUrl == null || photoUrl.isEmpty) continue;

      final durationSeconds = int.tryParse(session['duration']?.toString() ?? '') ?? 0;
      final stage = session['stage']?.toString();
      final difficulty = int.tryParse(session['difficulty']?.toString() ?? '');
      final toolsUsedRaw = session['tools_used'];
      final toolsUsed = toolsUsedRaw is List
          ? toolsUsedRaw.map((tool) => tool.toString()).toList()
          : const <String>[];
      final createdAt =
          DateTime.tryParse(session['created_at']?.toString() ?? '') ?? DateTime.now();

      posts.add(FeedPost(
        id: session['id'].toString(),
        type: FeedPostType.session,
        projectId: projectId,
        projectTitle: projectTitle,
        artist: username,
        slideCount: 1,
        views: 0,
        datePosted: createdAt,
        description: stage != null ? 'Working on: $stage' : 'A session from "$projectTitle".',
        toolsUsed: toolsUsed,
        timeTaken: _formatTimeTaken(durationSeconds),
        photoUrl: photoUrl,
        stage: stage,
        difficulty: difficulty,
      ));
    }
  }

  posts.sort((a, b) => b.datePosted.compareTo(a.datePosted));
  return posts;
});
