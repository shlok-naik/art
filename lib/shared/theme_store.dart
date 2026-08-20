import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's dark-mode preference on-device, following the same
/// SharedPreferences pattern as [LeagueSeenStore].
class ThemeStore {
  static const _darkModeKey = 'dark_mode_enabled';

  Future<bool> getIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setIsDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }
}
