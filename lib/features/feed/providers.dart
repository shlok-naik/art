import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import '../profile/providers.dart';
import '../projects/providers.dart';
import 'data/reactions_repository.dart';
import 'domain/feed_post.dart';

String _resolveBackendUrl() {
  final url = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
  // The Android emulator can't reach the host machine via localhost; it
  // needs the special 10.0.2.2 alias instead.
  if (!kIsWeb && Platform.isAndroid) {
    return url
        .replaceFirst('localhost', '10.0.2.2')
        .replaceFirst('127.0.0.1', '10.0.2.2');
  }
  return url;
}

final reactionsRepositoryProvider = Provider<ReactionsRepository>((ref) {
  return ReactionsRepository(ref.watch(supabaseClientProvider), _resolveBackendUrl());
});

/// Reaction counts for a session, as {reaction_type: count}.
final reactionCountsProvider =
    FutureProvider.autoDispose.family<Map<String, int>, String>((ref, sessionId) {
  return ref.watch(reactionsRepositoryProvider).fetchCounts(sessionId);
});

/// The current user's own reactions for a session (raw rows, so callers can
/// see both the reaction_type and the row id needed to update/delete it).
final myReactionsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, sessionId) {
  return ref.watch(reactionsRepositoryProvider).fetchMyReactions(sessionId);
});

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
