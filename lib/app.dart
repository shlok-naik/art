import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/providers.dart';
import 'features/profile/presentation/onboarding_screen.dart';
import 'features/profile/presentation/profile_setup_screen.dart';
import 'features/profile/providers.dart';
import 'features/shell/main_shell.dart';
import 'shared/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: const MaterialApp(
        title: 'Unfinished',
        home: AuthGate(),
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
