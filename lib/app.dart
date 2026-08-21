import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/providers.dart';
import 'features/profile/presentation/onboarding_screen.dart';
import 'features/profile/presentation/profile_setup_screen.dart';
import 'features/profile/providers.dart';
import 'features/shell/main_shell.dart';
import 'shared/app_styles.dart';
import 'shared/app_theme.dart';
import 'shared/joke_notification_service.dart';
import 'shared/revenue_cat_service.dart';
import 'shared/splash_screen.dart';
import 'shared/theme_providers.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  String? _revenueCatSyncedUserId;

  @override
  void initState() {
    super.initState();

    // Prompts for the OS notification permission on first launch, then
    // shows a free, local, on-device joke notification on every app open.
    JokeNotificationService().requestPermission();
    JokeNotificationService().showRandomJoke();

    // ref.listen (used in build) only fires on subsequent changes, so sync
    // once here too in case a session is already persisted on cold start.
    _syncRevenueCatIdentity(null, ref.read(authStateChangesProvider));
  }

  // Keeps RevenueCat's identity in sync with the authenticated Supabase
  // user, so entitlements (e.g. Unfinished Pro) follow the account across
  // devices instead of a per-install anonymous ID.
  void _syncRevenueCatIdentity(AsyncValue<AuthState>? previous, AsyncValue<AuthState> next) {
    final userId = next.value?.session?.user.id;
    if (userId == _revenueCatSyncedUserId) return;
    _revenueCatSyncedUserId = userId;

    if (userId != null) {
      RevenueCatService().login(userId);
    } else {
      RevenueCatService().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, _syncRevenueCatIdentity);

    final isDarkMode = ref.watch(darkModeProvider);
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    // Read by the `kInkColor`/`kSurfaceColor`/etc. tokens in app_styles.dart
    // so plain field-style color reads throughout the app resolve against
    // the current theme without threading BuildContext everywhere. Set here,
    // synchronously before the tree below is (re)built, and paired with the
    // ValueKey below so toggling dark mode fully remounts every screen and
    // picks up the new value instead of leaving stale colors painted.
    appBrightness = brightness;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
              systemNavigationBarColor: Colors.black,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Unfinished',
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: KeyedSubtree(
          key: ValueKey(brightness),
          child: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (state) {
        final user = state.session?.user;
        if (user == null) {
          return const LoginScreen();
        }
        return const _ProfileGate();
      },
      loading: () => const SplashScreen(),
      error: (error, stack) => Scaffold(
        body: SafeArea(child: AppErrorState(error: error)),
      ),
    );
  }
}

class _ProfileGate extends ConsumerStatefulWidget {
  const _ProfileGate();

  @override
  ConsumerState<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends ConsumerState<_ProfileGate> {
  bool _hasCompletedOnboarding = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          if (_hasCompletedOnboarding) return const ProfileSetupScreen();
          return OnboardingScreen(onComplete: () => setState(() => _hasCompletedOnboarding = true));
        }
        return const MainShell();
      },
      loading: () => const SplashScreen(),
      error: (error, stack) => Scaffold(
        body: SafeArea(
          child: AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
        ),
      ),
    );
  }
}
