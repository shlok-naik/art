import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/providers.dart';
import 'features/profile/presentation/onboarding_screen.dart';
import 'features/profile/presentation/profile_setup_screen.dart';
import 'features/profile/providers.dart';
import 'features/shell/main_shell.dart';
import 'shared/joke_notification_service.dart';
import 'shared/onesignal_service.dart';
import 'shared/splash_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _oneSignalDialogShown = false;

  @override
  void initState() {
    super.initState();

    // Retained on the State so OneSignal's (weakly-held) observer isn't
    // dropped immediately after this call, and so the dialog can be shown
    // once, whenever the subscription actually registers.
    OneSignalService().addPushSubscriptionObserver((state) {
      _maybeShowOneSignalDialog(state.current.id);
    });
    // The subscription may already be server-assigned before the observer
    // attaches, so check the current value immediately too.
    _maybeShowOneSignalDialog(OneSignalService().pushSubscriptionId);

    // Free, on-device notification (not a paid OneSignal send) shown on
    // every app open.
    JokeNotificationService().showRandomJoke();
  }

  bool _isRegistered(String? id) => id != null && id.isNotEmpty && !id.startsWith('local-');

  void _maybeShowOneSignalDialog(String? subscriptionId) {
    if (!_isRegistered(subscriptionId) || _oneSignalDialogShown) return;
    _oneSignalDialogShown = true;

    final context = _navigatorKey.currentContext;
    if (context == null) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Your OneSignal SDK integration is complete!'),
        content: const Text(
          'You can now send Push Notifications & In-App Messages through OneSignal. '
          'Tap below to enable push notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              OneSignalService().requestPermission();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Unfinished',
        home: const AuthGate(),
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
        body: Center(child: Text('Error: $error')),
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
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
