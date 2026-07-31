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

    final sessionIds = [for (final session in sessions) session['id'].toString()];
    var viewCounts = const <String, int>{};
    if (sessionIds.isNotEmpty) {
      final viewRows = await _client
          .from('session_view_counts')
          .select('session_id, view_count')
          .inFilter('session_id', sessionIds);
      viewCounts = {
        for (final row in List<Map<String, dynamic>>.from(viewRows))
          row['session_id'].toString(): int.tryParse(row['view_count'].toString()) ?? 0,
      };
    }

    return [
      for (final session in sessions)
        FeedPost.fromRow(
          session: session,
          project: (session['projects'] as Map?)?.cast<String, dynamic>() ?? const {},
          artist: usernames[(session['projects'] as Map?)?['user_id']?.toString()] ?? 'unknown',
          views: viewCounts[session['id'].toString()] ?? 0,
        ),
    ];
  }
}
