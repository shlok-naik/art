import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_spacing.dart';
import '../../../shared/app_styles.dart';
import '../domain/league.dart';

/// Full-screen celebration shown the moment a newly-ended league's win is
/// first noticed, with a confetti burst. Pushed by [MainShell] whenever
/// [newlyWonTrophiesProvider] reports a fresh win — same role
/// [AchievementCelebrationScreen] plays for achievement unlocks.
class LeagueTrophyCelebrationScreen extends StatefulWidget {
  const LeagueTrophyCelebrationScreen({super.key, required this.trophy});

  final LeagueTrophy trophy;

  @override
  State<LeagueTrophyCelebrationScreen> createState() => _LeagueTrophyCelebrationScreenState();
}

class _LeagueTrophyCelebrationScreenState extends State<LeagueTrophyCelebrationScreen> {
  late final _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  @override
  void initState() {
    super.initState();
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trophy = widget.trophy;

    return Scaffold(
      backgroundColor: kAccentColor,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "You won this week's league!",
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    if (trophy.photoUrl.isNotEmpty)
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kNavyColor,
                          border: Border.all(color: kGoldColor, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(imageUrl: trophy.photoUrl, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kNavyColor,
                          border: Border.all(color: kGoldColor, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: const AppIcon(AppIcons.trophy, size: 80, color: kGoldColor, strokeWidth: 1.2),
                      ),
                    const SizedBox(height: AppSpacing.space24),
                    Text(
                      trophy.themeTitle,
                      textAlign: TextAlign.center,
                      style: appHeadlineStyle(fontSize: 30, color: Colors.white, italic: true),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      'Won with ★ ${trophy.stars} — added to your trophy cabinet.',
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                    const SizedBox(height: 36),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space32, vertical: AppSpacing.space12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Nice!',
                          style: appBodyStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kAccentColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 8,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [Colors.white, kGoldColor, kNavyColor, Colors.lightBlueAccent],
          ),
        ],
      ),
    );
  }
}
