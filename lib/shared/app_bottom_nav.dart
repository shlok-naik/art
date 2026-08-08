import 'package:flutter/material.dart';

import 'app_icons.dart';
import 'app_styles.dart';

/// Persistent bottom nav shown across the four main tabs (Home, Feed,
/// Followed, Profile) so any of them is reachable from any other, without
/// affecting the back-button behavior of screens pushed on top via
/// Navigator (those still cover this bar, as usual). Navy bar with the
/// active tab's icon sitting in a cobalt pill.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 76 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset + 4),
      color: kNavyColor,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: AppIcons.home,
                  label: 'Home',
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: AppIcons.feed,
                  label: 'Feed',
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: AppIcons.followed,
                  label: 'Followed',
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: AppIcons.profile,
                  label: 'Profile',
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
            ],
          ),
          // Sized and positioned to intentionally overflow past the bottom of
          // the screen, so the mascot's legs/feet run off the edge. Decorative
          // only — taps pass through to whatever is underneath.
          Positioned(
            bottom: -18 - bottomInset,
            right: 10,
            child: IgnorePointer(
              child: Image.asset('assets/branding/mascot.png', height: 64),
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

  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(
                color: kAccentColor,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: AppIcon(icon, color: Colors.white),
            )
          else
            Padding(
              // Keeps icon centers level between the pill-wrapped active icon
              // and bare inactive ones.
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: AppIcon(icon, color: Colors.white70),
            ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appBodyStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              color: isActive ? Colors.white : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
