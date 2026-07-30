import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReactionsRepository {
  ReactionsRepository(this._client, this._backendUrl);

  final SupabaseClient _client;
  final String _backendUrl;

  Map<String, String> get _headers {
    final token = _client.auth.currentSession?.accessToken;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Reaction counts for a session, as {reaction_type: count}.
  Future<Map<String, int>> fetchCounts(String sessionId) async {
    final uri = Uri.parse('$_backendUrl/api/reaction_counts').replace(queryParameters: {
      'session_id': 'eq.$sessionId',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load reaction counts (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as List;
    return {
      for (final row in decoded.cast<Map<String, dynamic>>())
        row['reaction_type'].toString(): int.tryParse(row['count'].toString()) ?? 0,
    };
  }

  /// The current user's own reactions for a session — at most one 'vote'
  /// (up/down) row and one 'emoji' row, per the table's unique constraint.
  Future<List<Map<String, dynamic>>> fetchMyReactions(String sessionId) async {
    final userId = currentUserId;
    if (userId == null) return [];
    final uri = Uri.parse('$_backendUrl/api/reactions').replace(queryParameters: {
      'session_id': 'eq.$sessionId',
      'user_id': 'eq.$userId',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load your reactions (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> createReaction({required String sessionId, required String reactionType}) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not signed in');
    final response = await http.post(
      Uri.parse('$_backendUrl/api/reactions'),
      headers: _headers,
      body: jsonEncode({
        'session_id': sessionId,
        'user_id': userId,
        'reaction_type': reactionType,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to react (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> updateReaction({required String reactionId, required String reactionType}) async {
    final response = await http.patch(
      Uri.parse('$_backendUrl/api/reactions/$reactionId'),
      headers: _headers,
      body: jsonEncode({'reaction_type': reactionType}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to update reaction (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> deleteReaction(String reactionId) async {
    final response = await http.delete(
      Uri.parse('$_backendUrl/api/reactions/$reactionId'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to remove reaction (${response.statusCode}): ${response.body}');
    }
  }
}
