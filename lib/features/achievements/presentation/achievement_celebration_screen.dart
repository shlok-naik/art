import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../domain/achievement.dart';

/// Full-screen celebration shown the moment an achievement is newly
/// unlocked, with a confetti burst. Pushed by [MainShell] whenever
/// [newlyUnlockedAchievementsProvider] reports a fresh unlock.
class AchievementCelebrationScreen extends StatefulWidget {
  const AchievementCelebrationScreen({super.key, required this.achievement});

  final Achievement achievement;

  @override
  State<AchievementCelebrationScreen> createState() => _AchievementCelebrationScreenState();
}

class _AchievementCelebrationScreenState extends State<AchievementCelebrationScreen> {
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
    final achievement = widget.achievement;

    return Scaffold(
      backgroundColor: kAccentColor,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Achievement unlocked!',
                      style: GoogleFonts.chewy(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: kBorderColor, width: kBorderWidth),
                      ),
                      alignment: Alignment.center,
                      child: Text(achievement.emoji, style: const TextStyle(fontSize: 80)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      achievement.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chewy(fontSize: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement.description,
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 36),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: kBorderColor, width: kBorderWidth),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Nice!',
                          style: appBodyStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kAccentColor),
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
            colors: const [Colors.white, kAccentColor, Colors.amber, Colors.pinkAccent, Colors.lightBlueAccent],
          ),
        ],
      ),
    );
  }
}
