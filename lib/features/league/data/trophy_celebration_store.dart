import 'package:shared_preferences/shared_preferences.dart';

/// Device-local record of trophy celebrations already shown to this user.
/// This is presentation state, not shared application data, so it does not
/// need a database table or a cross-device sync guarantee.
class TrophyCelebrationStore {
  String _key(String userId) => 'seen_trophy_leagues_$userId';

  Future<Set<String>> getSeenLeagueIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(userId)) ?? const <String>[]).toSet();
  }

  Future<void> markSeen(String userId, String leagueId) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = await getSeenLeagueIds(userId);
    if (!seen.add(leagueId)) return;
    await prefs.setStringList(_key(userId), seen.toList()..sort());
  }
}
