import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../shared/app_bottom_nav.dart';
import '../achievements/domain/achievement.dart';
import '../achievements/presentation/achievement_celebration_screen.dart';
import '../achievements/providers.dart';
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
///
/// Tabs live in a [PageView] (not an [IndexedStack]) purely for the slide
/// transition when switching — swiping is disabled (`NeverScrollableScrollPhysics`)
/// so the only way to change page is [mainTabIndexProvider], keeping tab
/// switches exclusively a bottom-nav gesture. All four tabs still stay built
/// simultaneously, same as IndexedStack, so scroll position/form state in an
/// inactive tab survives switching away and back.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final _pageController = PageController(initialPage: ref.read(mainTabIndexProvider));

  static const _tabs = [
    _KeepAliveTab(child: HomeScreen()),
    _KeepAliveTab(child: FeedScreen()),
    _KeepAliveTab(child: FollowedScreen()),
    _KeepAliveTab(child: ProfileViewScreen()),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(mainTabIndexProvider);

    ref.listen<int>(mainTabIndexProvider, (previous, next) {
      if (!_pageController.hasClients) return;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });

    ref.listen<AsyncValue<List<Achievement>>>(newlyUnlockedAchievementsProvider, (previous, next) {
      final achievements = next.value;
      if (achievements == null || achievements.isEmpty) return;

      final celebratedNotifier = ref.read(celebratedAchievementKeysProvider.notifier);
      final alreadyCelebrated = celebratedNotifier.state;
      final toCelebrate = [
        for (final achievement in achievements)
          if (!alreadyCelebrated.contains(achievement.key)) achievement,
      ];
      if (toCelebrate.isEmpty) return;

      celebratedNotifier.state = {...alreadyCelebrated, for (final a in toCelebrate) a.key};
      _celebrate(context, toCelebrate);
    });

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: index,
        onTap: (i) => ref.read(mainTabIndexProvider.notifier).state = i,
      ),
    );
  }

  /// Pushes a celebration screen per newly-unlocked achievement, one after
  /// another — rare to have more than one at once, but possible (e.g. the
  /// first check after a lot of existing activity).
  void _celebrate(BuildContext context, List<Achievement> achievements) {
    final navigator = Navigator.of(context, rootNavigator: true);
    Future(() async {
      for (final achievement in achievements) {
        await navigator.push(
          MaterialPageRoute(builder: (_) => AchievementCelebrationScreen(achievement: achievement)),
        );
      }
    });
  }
}

/// Keeps [child] alive while scrolled off-screen in the shell's [PageView] —
/// without this, an inactive tab can get disposed and rebuilt from scratch
/// (losing scroll position, form state) the way [IndexedStack] never would.
class _KeepAliveTab extends StatefulWidget {
  const _KeepAliveTab({required this.child});

  final Widget child;

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
