import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which league the signed-in user has last acknowledged on this
/// device, so a freshly-restarted league (a different id from the one
/// stored here) can be flagged as "new" — driving the home screen badge and
/// the one-time "create a project for this league?" prompt.
class LeagueSeenStore {
  static const _lastSeenLeagueIdKey = 'league_last_seen_id';

  Future<String?> getLastSeenLeagueId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSeenLeagueIdKey);
  }

  Future<void> markSeen(String leagueId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenLeagueIdKey, leagueId);
  }
}
