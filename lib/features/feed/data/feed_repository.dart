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

  /// A given user's posted sessions, newest first — used by public profile pages.
  Future<List<FeedPost>> fetchPostsByUser(String userId) => _fetchPosts(ownerId: userId);

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
    var avatarUrls = const <String, String>{};
    if (userIds.isNotEmpty) {
      final profileRows = await _client
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', userIds.toList());
      final profiles = List<Map<String, dynamic>>.from(profileRows);
      usernames = {
        for (final profile in profiles) profile['id'].toString(): profile['username'].toString(),
      };
      avatarUrls = {
        for (final profile in profiles)
          if (profile['avatar_url']?.toString() case final url? when url.isNotEmpty)
            profile['id'].toString(): url,
      };
    }

    return [
      for (final session in sessions)
        FeedPost.fromRow(
          session: session,
          project: (session['projects'] as Map?)?.cast<String, dynamic>() ?? const {},
          artist: usernames[(session['projects'] as Map?)?['user_id']?.toString()] ?? 'unknown',
          views: int.tryParse(session['view_count']?.toString() ?? '') ?? 0,
          artistAvatarUrl: avatarUrls[(session['projects'] as Map?)?['user_id']?.toString()],
        ),
    ];
  }
}
