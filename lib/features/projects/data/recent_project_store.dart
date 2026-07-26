import 'package:shared_preferences/shared_preferences.dart';

class RecentProjectStore {
  static const _lastOpenedProjectIdKey = 'last_opened_project_id';

  Future<void> setLastOpenedProjectId(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedProjectIdKey, projectId);
  }

  Future<String?> getLastOpenedProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastOpenedProjectIdKey);
  }
}
