import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionsRepository {
  SessionsRepository(this._client, this._backendUrl);

  final SupabaseClient _client;
  final String _backendUrl;

  static const _photoBucket = 'session-photos';

  Map<String, String> get _headers {
    final token = _client.auth.currentSession?.accessToken;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Map<String, dynamic>>> fetchSessions(String projectId) async {
    final uri = Uri.parse('$_backendUrl/api/sessions').replace(queryParameters: {
      'project_id': 'eq.$projectId',
      'order': 'created_at.desc',
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load sessions (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as List;
    return decoded.cast<Map<String, dynamic>>();
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
    final response = await http.post(
      Uri.parse('$_backendUrl/api/sessions'),
      headers: _headers,
      body: jsonEncode({
        'project_id': projectId,
        'duration': durationSeconds,
        'photo_url': photoUrl,
        'stage': stage,
        'tools_used': toolsUsed,
        'difficulty': difficulty,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to create session (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> updateSessionPhoto(String sessionId, String photoUrl) async {
    final response = await http.patch(
      Uri.parse('$_backendUrl/api/sessions/$sessionId'),
      headers: _headers,
      body: jsonEncode({'photo_url': photoUrl}),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to update session (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> updateSessionDetails({
    required String sessionId,
    required String stage,
    required List<String> toolsUsed,
    required int difficulty,
  }) async {
    final response = await http.patch(
      Uri.parse('$_backendUrl/api/sessions/$sessionId'),
      headers: _headers,
      body: jsonEncode({
        'stage': stage,
        'tools_used': toolsUsed,
        'difficulty': difficulty,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to update session (${response.statusCode}): ${response.body}');
    }
  }
}
