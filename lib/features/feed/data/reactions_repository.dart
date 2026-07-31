import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/reactions.dart';

class ReactionsRepository {
  ReactionsRepository(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Reaction counts for a session, as {reaction_type: count}.
  Future<Map<String, int>> fetchCounts(String sessionId) async {
    final rows = await _client
        .from('reaction_counts')
        .select('reaction_type, count')
        .eq('session_id', sessionId);
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['reaction_type'].toString(): int.tryParse(row['count'].toString()) ?? 0,
    };
  }

  /// The current user's own reactions for a session — at most one 'vote'
  /// (up/down) row and one 'emoji' row, per the table's unique constraint.
  Future<List<Map<String, dynamic>>> fetchMyReactions(String sessionId) async {
    final userId = currentUserId;
    if (userId == null) return const [];
    final rows = await _client
        .from('reactions')
        .select()
        .eq('session_id', sessionId)
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Inserts a reaction and returns the created row, so callers immediately
  /// have the real row id for follow-up updates/deletes.
  Future<Map<String, dynamic>> createReaction({
    required String sessionId,
    required String reactionType,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not signed in');
    final rows = await _client.from('reactions').insert({
      'session_id': sessionId,
      'user_id': userId,
      'reaction_type': reactionType,
      'kind': isVoteReactionType(reactionType) ? 'vote' : 'emoji',
    }).select();
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> updateReaction({required String reactionId, required String reactionType}) async {
    await _client.from('reactions').update({'reaction_type': reactionType}).eq('id', reactionId);
  }

  Future<void> deleteReaction(String reactionId) async {
    await _client.from('reactions').delete().eq('id', reactionId);
  }
}
