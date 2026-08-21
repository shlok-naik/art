import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../domain/achievement.dart';
import '../providers.dart';

/// Full achievement catalog for [userId], locked entries included (dimmed,
/// shown as 🔒). Tapping any tile — locked or unlocked — opens
/// [showAchievementDetail] with its description; unlocked ones get a
/// confetti burst, matching the celebration screen's visual language.
class AllAchievementsScreen extends ConsumerWidget {
  const AllAchievementsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAsync = ref.watch(unlockedAchievementsProvider(userId));

    return Scaffold(
      appBar: appThemedAppBar(context, 'Achievements'),
      body: unlockedAsync.when(
        data: (unlocked) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: achievementCatalog.length,
          itemBuilder: (context, index) {
            final achievement = achievementCatalog[index];
            final isUnlocked = unlocked.containsKey(achievement.key);
            return _AchievementTile(achievement: achievement, isUnlocked: isUnlocked);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppErrorState(
          error: error,
          onRetry: () => ref.invalidate(unlockedAchievementsProvider(userId)),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.isUnlocked});

  final Achievement achievement;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showAchievementDetail(context, achievement: achievement, isUnlocked: isUnlocked),
      child: Opacity(
        opacity: isUnlocked ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: appHardCardDecoration(radius: 14, shadowOffset: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isUnlocked ? achievement.emoji : '🔒', style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 3),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                maxLines: 2,
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

/// Shows [achievement]'s title/description in a dialog. Plays a confetti
/// burst only when [isUnlocked] — locked achievements preview what's ahead
/// without implying it's already been earned.
void showAchievementDetail(BuildContext context, {required Achievement achievement, required bool isUnlocked}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _AchievementDetailDialog(achievement: achievement, isUnlocked: isUnlocked),
  );
}

class _AchievementDetailDialog extends StatefulWidget {
  const _AchievementDetailDialog({required this.achievement, required this.isUnlocked});

  final Achievement achievement;
  final bool isUnlocked;

  @override
  State<_AchievementDetailDialog> createState() => _AchievementDetailDialogState();
}

class _AchievementDetailDialogState extends State<_AchievementDetailDialog> {
  late final _confettiController = ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    if (widget.isUnlocked) _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;
    final isUnlocked = widget.isUnlocked;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
            decoration: appHardCardDecoration(radius: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chewy(fontSize: 22, color: kInkColor),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF555555)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUnlocked ? kSuccessBgColor : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isUnlocked ? 'Unlocked' : 'Locked',
                    style: appBodyStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked ? kSuccessTextColor : const Color(0xFF888888),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                      color: kAccentColor,
                      border: Border.all(color: kBorderColor, width: kBorderWidth),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Close',
                      style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -30,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kSurfaceColor,
                border: Border.all(color: kBorderColor, width: kBorderWidth),
              ),
              alignment: Alignment.center,
              child: Text(isUnlocked ? achievement.emoji : '🔒', style: const TextStyle(fontSize: 34)),
            ),
          ),
          if (isUnlocked)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 20,
              maxBlastForce: 16,
              minBlastForce: 6,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [Colors.white, kAccentColor, Colors.amber, Colors.pinkAccent, Colors.lightBlueAccent],
            ),
        ],
      ),
    );
  }
}
