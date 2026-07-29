import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../shared/app_bottom_nav.dart';
import '../feed/presentation/feed_screen.dart';
import '../followed/presentation/followed_screen.dart';
import '../home/presentation/home_screen.dart';
import '../profile/presentation/profile_view_screen.dart';

/// Which of the four main tabs is currently showing. Any screen, no matter
/// how deep, can switch tabs via `ref.read(mainTabIndexProvider.notifier)`.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

/// Pops any pushed screens (League, Projects, project/session detail, etc.)
/// back to the main shell and switches to the requested tab. Used by the
/// bottom nav bar shown on those pushed screens, so every screen in the app
/// can jump straight to any tab without losing the shell's tab state.
void goToMainTab(BuildContext context, WidgetRef ref, int index) {
  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  ref.read(mainTabIndexProvider.notifier).state = index;
}

/// Root shell for the four main tabs (Home, Feed, Followed, Profile), with a
/// single persistent bottom nav bar so all four are reachable from any of
/// them. Screens pushed on top via Navigator (project details, league,
/// settings, etc.) still cover this shell and keep their own back button,
/// exactly as before.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _tabs = [
    HomeScreen(),
    FeedScreen(),
    FollowedScreen(),
    ProfileViewScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(mainTabIndexProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: AppBottomNav(
        currentIndex: index,
        onTap: (i) => ref.read(mainTabIndexProvider.notifier).state = i,
      ),
    );
  }
}
