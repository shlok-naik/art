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

  /// A given user's projects, newest first — used by the public profile's
  /// project circles, which need any user's projects, not just the
  /// signed-in user's (project rows are publicly readable).
  Future<List<Map<String, dynamic>>> fetchProjectsByUser(String userId) async {
    final rows = await _client
        .from('projects')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createProject(Map<String, dynamic> values) async {
    await _client.from('projects').insert(values);
  }

  /// Marks [id] as the signed-in user's most recently opened project — the
  /// Home screen's hero card reads this straight from the row, so it's
  /// consistent across every device/session instead of a device-local guess.
  Future<void> recordOpened(String id) async {
    await _client.from('projects').update({'last_opened_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
  }

  Future<void> updateCompletion(String id, int completionPercent) async {
    await _client.from('projects').update({'completion_percent': completionPercent}).eq('id', id);
  }

  /// Marks a project as finished: 100% complete and locked — no further
  /// sessions can be added to it. One-way; there's no "unfinish".
  Future<void> finishProject(String id) async {
    await _client
        .from('projects')
        .update({'completion_percent': 100, 'finished_status': true}).eq('id', id);
  }

  Future<void> deleteProject(String id) async {
    final deleted = await _client.from('projects').delete().eq('id', id).select('id');
    if (deleted.isEmpty) {
      throw Exception('Project was not deleted (not found, or not permitted)');
    }
  }
}
