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
    await _client.from('sessions').update({'photo_url': photoUrl}).eq('id', sessionId);
  }

  Future<void> updateSessionDetails({
    required String sessionId,
    required String stage,
    required List<String> toolsUsed,
    required int difficulty,
    required String name,
  }) async {
    await _client.from('sessions').update({
      'stage': stage,
      'tools_used': toolsUsed,
      'difficulty': difficulty,
      'name': name,
    }).eq('id', sessionId);
  }

  /// Records that the signed-in user viewed [sessionId]. Upserts on the
  /// (session_id, viewer_id) primary key so repeat views of the same post
  /// by the same viewer don't inflate the count.
  Future<void> recordView(String sessionId) async {
    final viewerId = _client.auth.currentUser?.id;
    if (viewerId == null) return;
    await _client.from('session_views').upsert(
      {'session_id': sessionId, 'viewer_id': viewerId},
      onConflict: 'session_id,viewer_id',
      ignoreDuplicates: true,
    );
  }

  /// Batched view counts for a set of sessions, as {session_id: count}.
  /// Sessions with zero views are simply absent from the map.
  Future<Map<String, int>> fetchViewCounts(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return const {};
    final rows = await _client
        .from('session_view_counts')
        .select('session_id, view_count')
        .inFilter('session_id', sessionIds);
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['session_id'].toString(): int.tryParse(row['view_count'].toString()) ?? 0,
    };
  }
}
