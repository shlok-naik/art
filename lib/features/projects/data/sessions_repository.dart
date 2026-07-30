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
  }) async {
    await _client.from('sessions').insert({
      'project_id': projectId,
      'duration': durationSeconds,
      'photo_url': photoUrl,
      'stage': stage,
      'tools_used': toolsUsed,
      'difficulty': difficulty,
    });
  }

  Future<void> updateSessionPhoto(String sessionId, String photoUrl) async {
    await _client.from('sessions').update({'photo_url': photoUrl}).eq('id', sessionId);
  }

  Future<void> updateSessionDetails({
    required String sessionId,
    required String stage,
    required List<String> toolsUsed,
    required int difficulty,
  }) async {
    await _client.from('sessions').update({
      'stage': stage,
      'tools_used': toolsUsed,
      'difficulty': difficulty,
    }).eq('id', sessionId);
  }
}
