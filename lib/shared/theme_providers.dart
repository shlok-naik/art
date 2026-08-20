import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_store.dart';

/// The dark-mode preference read from disk before the widget tree is first
/// built (see `main.dart`), overridden into [ProviderScope] so
/// [DarkModeController.build] can pick it up without an async gap — that
/// keeps the very first frame in the right theme instead of flashing light
/// mode before a persisted dark preference loads.
final initialDarkModeProvider = Provider<bool>((ref) => false);

final themeStoreProvider = Provider<ThemeStore>((ref) => ThemeStore());

/// Whether dark mode is on, toggled from the Profile screen. Persists to
/// disk on every change via [ThemeStore] so the preference survives an app
/// restart.
final darkModeProvider = NotifierProvider<DarkModeController, bool>(DarkModeController.new);

class DarkModeController extends Notifier<bool> {
  @override
  bool build() => ref.read(initialDarkModeProvider);

  Future<void> setDarkMode(bool value) async {
    state = value;
    await ref.read(themeStoreProvider).setIsDarkMode(value);
  }

  Future<void> toggle() => setDarkMode(!state);
}
