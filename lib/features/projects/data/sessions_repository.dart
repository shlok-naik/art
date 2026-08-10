import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SessionsRepository {
  SessionsRepository(this._client);

  final SupabaseClient _client;

  static const _photoBucket = 'session-photos';

  Future<List<Map<String, dynamic>>> fetchSessions(String projectId) async {
    final rows = await _client
        .from('sessions')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Every session across the given projects in one query, so callers that
  /// need all of a user's sessions (analytics) don't fetch per-project.
  Future<List<Map<String, dynamic>>> fetchSessionsForProjects(List<String> projectIds) async {
    if (projectIds.isEmpty) return const [];
    final rows = await _client
        .from('sessions')
        .select()
        .inFilter('project_id', projectIds)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String> uploadPhoto(Uint8List bytes, String projectId) async {
    final userId = _client.auth.currentUser?.id ?? 'anonymous';
    final path = '$userId/$projectId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from(_photoBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return _client.storage.from(_photoBucket).getPublicUrl(path);
  }

  Future<void> createSession({
    required String projectId,
    required int durationSeconds,
    required String photoUrl,
    required String stage,
    required List<String> toolsUsed,
    required int difficulty,
    required String name,
  }) async {
    await _client.from('sessions').insert({
      'project_id': projectId,
      'duration': durationSeconds,
      'photo_url': photoUrl,
      'stage': stage,
      'tools_used': toolsUsed,
      'difficulty': difficulty,
      'name': name,
    });
  }

  Future<void> updateSessionPhoto(String sessionId, String photoUrl) async {
    // .select() so a zero-row result (RLS silently filtered the write,
    // e.g. this isn't your session) surfaces as an error instead of the
    // caller believing the save succeeded — same pattern as deleteProject.
    final updated =
        await _client.from('sessions').update({'photo_url': photoUrl}).eq('id', sessionId).select('id');
    if (updated.isEmpty) {
      throw Exception('Photo was not saved (session not found, or not permitted)');
    }
  }

  Future<void> updateSessionDetails({
    required String sessionId,
    required String stage,
    required List<String> toolsUsed,
    required int difficulty,
    required String name,
  }) async {
    final updated = await _client.from('sessions').update({
      'stage': stage,
      'tools_used': toolsUsed,
      'difficulty': difficulty,
      'name': name,
    }).eq('id', sessionId).select('id');
    if (updated.isEmpty) {
      throw Exception('Details were not saved (session not found, or not permitted)');
    }
  }

  /// Atomically increments the post's aggregate view count. Viewers are not
  /// stored, so this intentionally measures total opens rather than unique
  /// viewers.
  Future<void> recordView(String sessionId) async {
    await _client.rpc('record_session_view', params: {'p_session_id': sessionId});
  }

  /// Batched view counts for a set of sessions, as {session_id: count}.
  Future<Map<String, int>> fetchViewCounts(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return const {};
    final rows = await _client
        .from('sessions')
        .select('id, view_count')
        .inFilter('id', sessionIds);
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['id'].toString(): int.tryParse(row['view_count'].toString()) ?? 0,
    };
  }
}
