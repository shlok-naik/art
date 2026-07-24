import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';
import '../../profile/presentation/profile_view_screen.dart';
import '../../profile/providers.dart';

const _background = Color(0xFFF5F1E6);
const _sidebarBackground = Color(0xFFFBF9F1);
const _dividerColor = Color(0xFF2B2B26);
const _iconColor = Color(0xFF2B2B26);
const _actionsOuter = Color(0xFFB7BB84);
const _actionsInner = Color(0xFF9CA06A);
const _actionText = Color(0xFF2E2E28);
const _cardBackground = Color(0xFFCBCCAA);
const _cardMutedText = Color(0xFF8C8C77);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final displayName = profileAsync.value?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Row(
          children: [
            _Sidebar(
              onProfileTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileViewScreen()),
              ),
              onSignOut: () => ref.read(authRepositoryProvider).signOut(),
            ),
            Container(width: 2, color: _dividerColor),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $displayName!',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _actionText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ready to create a masterpiece?',
                      style: TextStyle(fontSize: 16, color: _cardMutedText),
                    ),
                    const SizedBox(height: 20),
                    const _QuickActions(),
                    const SizedBox(height: 20),
                    const _BottomCards(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.onProfileTap, required this.onSignOut});

  final VoidCallback onProfileTap;
  final VoidCallback onSignOut;

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      color: _sidebarBackground,
      child: Column(
        children: [
          const SizedBox(height: 20),
          _SidebarIcon(icon: Icons.menu, onTap: () => _comingSoon(context, 'Menu')),
          const SizedBox(height: 28),
          _SidebarIcon(icon: Icons.home, filled: true, onTap: () {}),
          const SizedBox(height: 28),
          _SidebarIcon(icon: Icons.search, onTap: () => _comingSoon(context, 'Search')),
          const SizedBox(height: 28),
          _SidebarIcon(icon: Icons.emoji_events, onTap: () => _comingSoon(context, 'Achievements')),
          const SizedBox(height: 28),
          _SidebarIcon(icon: Icons.send, onTap: () => _comingSoon(context, 'Share')),
          const SizedBox(height: 28),
          _SidebarIcon(icon: Icons.bar_chart, onTap: () => _comingSoon(context, 'Analytics')),
          const Spacer(),
          _SidebarIcon(icon: Icons.person, onTap: onProfileTap),
          const SizedBox(height: 28),
          _SidebarIcon(icon: Icons.settings, onTap: onSignOut),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({required this.icon, required this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 28, color: _iconColor),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _actionsOuter,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(child: _ActionTile(label: 'Create new project')),
              SizedBox(width: 16),
              Expanded(child: _ActionTile(label: 'View other projects')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _ActionTile(label: 'Continue previous project')),
              SizedBox(width: 16),
              Expanded(child: _ActionTile(label: 'View all projects')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label coming soon')),
        );
      },
      child: Container(
        height: 130,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _actionsInner,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _actionText,
          ),
        ),
      ),
    );
  }
}

class _BottomCards extends StatelessWidget {
  const _BottomCards();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        final analytics = const _AnalyticsCard();
        final posts = const _PostsCard();
        if (isNarrow) {
          return Column(
            children: [analytics, const SizedBox(height: 16), posts],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: analytics),
              const SizedBox(width: 16),
              Expanded(child: posts),
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard();

  static const _bars = [
    (label: 'Sketching', hours: 60.0, color: Color(0xFF5B7FE0)),
    (label: 'Shading', hours: 45.0, color: Color(0xFFB39DEB)),
    (label: 'Rendering', hours: 78.0, color: Color(0xFFF2B66D)),
    (label: 'Painting', hours: 30.0, color: Color(0xFFF2D94E)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _cardMutedText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'View your usage details',
            style: TextStyle(fontSize: 14, color: _cardMutedText),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _YAxis(),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final bar in _bars)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _Bar(
                              label: bar.label,
                              hours: bar.hours,
                              color: bar.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.center,
            child: Text(
              'Stage',
              style: TextStyle(fontSize: 12, color: _cardMutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _YAxis extends StatelessWidget {
  const _YAxis();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text('80', style: TextStyle(fontSize: 11, color: _cardMutedText)),
          Text('60', style: TextStyle(fontSize: 11, color: _cardMutedText)),
          Text('40', style: TextStyle(fontSize: 11, color: _cardMutedText)),
          Text('20', style: TextStyle(fontSize: 11, color: _cardMutedText)),
          Text('0', style: TextStyle(fontSize: 11, color: _cardMutedText)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.hours, required this.color});

  final String label;
  final double hours;
  final Color color;

  static const _maxHours = 80.0;
  static const _chartHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    final barHeight = (hours / _maxHours) * _chartHeight;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: _chartHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                hours.toInt().toString(),
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: _cardMutedText),
        ),
      ],
    );
  }
}

class _PostsCard extends StatelessWidget {
  const _PostsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Posts',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _cardMutedText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'See the love your artwork is getting!',
            style: TextStyle(fontSize: 14, color: _cardMutedText),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(Icons.favorite, color: Color(0xFFC0392B), size: 48),
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF5B8DEF),
                child: const Icon(Icons.thumb_up, color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text('😂', style: TextStyle(fontSize: 44)),
              Transform.rotate(
                angle: -0.15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(1, 2)),
                    ],
                  ),
                  child: const Text(
                    'WOW!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: _actionText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
