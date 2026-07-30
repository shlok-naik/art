import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectsRepository {
  ProjectsRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');
    return userId;
  }

  /// The signed-in user's projects, newest first. Filtered by user_id
  /// explicitly because project rows are publicly readable (the feed needs
  /// them), so RLS alone no longer narrows this down to "mine".
  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final rows = await _client
        .from('projects')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createProject(Map<String, dynamic> values) async {
    await _client.from('projects').insert(values);
  }

  Future<void> deleteProject(String id) async {
    final deleted = await _client.from('projects').delete().eq('id', id).select('id');
    if (deleted.isEmpty) {
      throw Exception('Project was not deleted (not found, or not permitted)');
    }
  }
}
