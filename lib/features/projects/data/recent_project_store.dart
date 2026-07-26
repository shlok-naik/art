import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RecentProjectStore {
  static const _openedAtKey = 'project_opened_at';

  Future<void> recordOpened(String projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _readRaw(prefs);
    raw[projectId] = DateTime.now().toIso8601String();
    await prefs.setString(_openedAtKey, jsonEncode(raw));
  }

  /// Maps project id -> when it was last opened. Sorting by this is the
  /// caller's responsibility.
  Future<Map<String, DateTime>> getOpenedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return _readRaw(prefs).map((id, iso) => MapEntry(id, DateTime.parse(iso)));
  }

  Map<String, String> _readRaw(SharedPreferences prefs) {
    final raw = prefs.getString(_openedAtKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }
}
