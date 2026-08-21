import 'package:flutter/material.dart';

import '../../../shared/app_styles.dart';
import '../domain/achievement.dart';
import 'all_achievements_screen.dart';

/// Small unlocked-achievement card used in profile "Achievements" rows —
/// tapping it opens the same detail dialog as the full catalog screen.
class AchievementChip extends StatelessWidget {
  const AchievementChip({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showAchievementDetail(context, achievement: achievement, isUnlocked: true),
      child: Tooltip(
        message: achievement.description,
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: appHardCardDecoration(radius: 14, shadowOffset: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(achievement.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 3),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appBodyStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kInkColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
