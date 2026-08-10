import 'package:flutter/material.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_spacing.dart';
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
      borderRadius: BorderRadius.circular(20),
      onTap: () => showAchievementDetail(context, achievement: achievement, isUnlocked: true),
      child: Tooltip(
        message: achievement.description,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8, horizontal: AppSpacing.space12),
          decoration: BoxDecoration(
            color: kNavyColor,
            border: Border.all(color: kGoldColor, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(achievement.icon, size: 14, color: kGoldColor),
              const SizedBox(width: AppSpacing.space8),
              Text(
                achievement.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGoldColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
