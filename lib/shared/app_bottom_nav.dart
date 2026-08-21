import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_styles.dart';

/// Persistent bottom nav shown across the four main tabs (Home, Feed,
/// Followed, Profile) so any of them is reachable from any other, without
/// affecting the back-button behavior of screens pushed on top via
/// Navigator (those still cover this bar, as usual).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 104,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              border: Border(top: BorderSide(color: kBorderColor, width: kBorderWidth)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home,
                    label: 'Home',
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.article_outlined,
                    label: 'Feed',
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                ),
                const SizedBox(width: 70),
                Expanded(
                  child: _NavItem(
                    icon: Icons.groups_outlined,
                    label: 'Followed',
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ),
              ],
            ),
          ),
          // Sized and positioned to intentionally overflow past the bottom of the
          // screen, so the mascot's legs/feet run off the edge. Height is kept
          // low enough that the top of the mascot doesn't creep above this bar
          // and paint over content sitting above it.
          Positioned(
            bottom: -32,
            child: GestureDetector(
              onTap: () {},
              child: Image.asset('assets/branding/mascot.png', height: 128),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? kAccentColor : kInkColor;
    final child = CircleAvatar(
      radius: 16,
      backgroundColor: Colors.transparent,
      child: Icon(icon, color: color),
    );

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (label.isNotEmpty)
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.chewy(
                fontSize: 12,
                color: color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
        ],
      ),
    );
  }
}
