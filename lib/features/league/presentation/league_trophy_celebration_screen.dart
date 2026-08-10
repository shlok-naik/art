import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "You won this week's league!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chewy(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    if (trophy.photoUrl.isNotEmpty)
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: kBorderColor, width: kBorderWidth),
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
                          color: Colors.white,
                          border: Border.all(color: kBorderColor, width: kBorderWidth),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🏆', style: TextStyle(fontSize: 80)),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      trophy.themeTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chewy(fontSize: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Won with ⭐ ${trophy.stars} — added to your trophy cabinet.',
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
