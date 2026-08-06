import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/comment.dart';

class CommentsRepository {
  CommentsRepository(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// One query for the comments, then a batched profiles lookup to resolve
  /// usernames — same shape as FeedRepository, since there's no direct
  /// foreign key from comments to profiles (both merely reference
  /// auth.users) for PostgREST to embed automatically.
  Future<List<Comment>> fetchComments(String sessionId) async {
    final rows = await _client
        .from('comments')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    final comments = List<Map<String, dynamic>>.from(rows);

    final userIds = {for (final c in comments) c['user_id'].toString()};
    var usernames = const <String, String>{};
    if (userIds.isNotEmpty) {
      final profileRows = await _client
          .from('profiles')
          .select('id, username')
          .inFilter('id', userIds.toList());
      usernames = {
        for (final p in List<Map<String, dynamic>>.from(profileRows))
          p['id'].toString(): p['username'].toString(),
      };
    }

    return [
      for (final c in comments)
        Comment(
          id: c['id'].toString(),
          sessionId: c['session_id'].toString(),
          userId: c['user_id'].toString(),
          username: usernames[c['user_id'].toString()] ?? 'unknown',
          body: c['body'].toString(),
          createdAt: DateTime.parse(c['created_at'].toString()),
        ),
    ];
  }

  /// Inserts a comment and returns its id/created_at; the caller already
  /// knows the posting user's own username, so there's no need to re-fetch
  /// the profiles table just to build the full [Comment].
  Future<Map<String, dynamic>> createComment({
    required String sessionId,
    required String body,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not signed in');
    final rows = await _client.from('comments').insert({
      'session_id': sessionId,
      'user_id': userId,
      'body': body,
    }).select();
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  /// Total comments [userId] has posted, across every session — used for
  /// comment-count achievements.
  Future<int> fetchCommentCountByUser(String userId) async {
    final rows = await _client.from('comments').select('id').eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows).length;
  }

  Future<void> reportComment(String commentId, {String? reason}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not signed in');
    await _client.from('comment_reports').insert({
      'comment_id': commentId,
      'reporter_id': userId,
      'reason': reason,
    });
  }
}
