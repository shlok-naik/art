import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/feed_post.dart';

class FeedRepository {
  FeedRepository(this._client);

  final SupabaseClient _client;

  /// Every posted session across all users, newest first.
  Future<List<FeedPost>> fetchAllPosts() => _fetchPosts(ownerId: null);

  /// Only the signed-in user's own posted sessions, newest first.
  Future<List<FeedPost>> fetchMyPosts() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Future.value(const []);
    return _fetchPosts(ownerId: userId);
  }

  /// One query for the sessions (with their project embedded for the title
  /// and owner), then one batched profiles lookup to resolve artist names.
  /// Ownership is read off the embedded project row, which RLS guarantees is
  /// populated, rather than sessions.user_id (nullable on older rows).
  Future<List<FeedPost>> _fetchPosts({required String? ownerId}) async {
    var query = _client
        .from('sessions')
        .select('*, projects!inner(id, title, user_id)')
        .not('photo_url', 'is', null)
        .neq('photo_url', '');
    if (ownerId != null) {
      query = query.eq('projects.user_id', ownerId);
    }
    final rows = await query.order('created_at', ascending: false);
    final sessions = List<Map<String, dynamic>>.from(rows);

    final userIds = <String>{
      for (final session in sessions)
        if ((session['projects'] as Map?)?['user_id'] != null)
          (session['projects'] as Map)['user_id'].toString(),
    };
    var usernames = const <String, String>{};
    if (userIds.isNotEmpty) {
      final profileRows = await _client
          .from('profiles')
          .select('id, username')
          .inFilter('id', userIds.toList());
      usernames = {
        for (final profile in List<Map<String, dynamic>>.from(profileRows))
          profile['id'].toString(): profile['username'].toString(),
      };
    }

    return [for (final session in sessions) _toPost(session, usernames)];
  }

  FeedPost _toPost(Map<String, dynamic> session, Map<String, String> usernames) {
    final project = (session['projects'] as Map?)?.cast<String, dynamic>() ?? const {};
    final projectId = project['id']?.toString() ?? session['project_id'].toString();
    final projectTitle = project['title']?.toString() ?? projectId;
    final ownerId = project['user_id']?.toString() ?? '';

    final durationSeconds = int.tryParse(session['duration']?.toString() ?? '') ?? 0;
    final stage = session['stage']?.toString();
    final toolsUsedRaw = session['tools_used'];

    return FeedPost(
      id: session['id'].toString(),
      type: FeedPostType.session,
      projectId: projectId,
      projectTitle: projectTitle,
      userId: ownerId,
      artist: usernames[ownerId] ?? 'unknown',
      slideCount: 1,
      views: 0,
      datePosted: DateTime.tryParse(session['created_at']?.toString() ?? '') ?? DateTime.now(),
      description: stage != null ? 'Working on: $stage' : 'A session from "$projectTitle".',
      toolsUsed: toolsUsedRaw is List
          ? toolsUsedRaw.map((tool) => tool.toString()).toList()
          : const <String>[],
      timeTaken: _formatTimeTaken(durationSeconds),
      photoUrl: session['photo_url']?.toString(),
      stage: stage,
      difficulty: int.tryParse(session['difficulty']?.toString() ?? ''),
    );
  }

  static String _formatTimeTaken(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    return '${minutes}m';
  }
}
