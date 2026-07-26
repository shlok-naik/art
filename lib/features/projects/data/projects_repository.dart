import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectsRepository {
  ProjectsRepository(this._client, this._backendUrl);

  final SupabaseClient _client;
  final String _backendUrl;

  Map<String, String> get _headers {
    final token = _client.auth.currentSession?.accessToken;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final response = await http.get(
      Uri.parse('$_backendUrl/api/projects'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load projects (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> createProject(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/api/projects'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to create project (${response.statusCode}): ${response.body}');
    }
  }

  Future<void> deleteProject(String id) async {
    final response = await http.delete(
      Uri.parse('$_backendUrl/api/projects/$id'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception('Failed to delete project (${response.statusCode}): ${response.body}');
    }
  }
}
