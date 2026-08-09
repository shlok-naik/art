import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../domain/league.dart';

/// Small won-league card used in the profile "Trophy Cabinet" row —
/// tapping it opens the same detail dialog as the full cabinet screen.
class LeagueTrophyChip extends StatelessWidget {
  const LeagueTrophyChip({super.key, required this.trophy});

  final LeagueTrophy trophy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showLeagueTrophyDetail(context, trophy: trophy),
      child: Tooltip(
        message: trophy.themeTitle,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: appFlatCardDecoration(radius: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AppIcons.trophy, size: 14, color: kGoldColor),
              const SizedBox(width: 6),
              Text(
                trophy.themeTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [trophy]'s theme, winning entry, and star count in a dialog, with
/// a confetti burst — every trophy shown here was actually won, so unlike
/// the achievement detail dialog there's no locked/unlocked branch.
void showLeagueTrophyDetail(BuildContext context, {required LeagueTrophy trophy}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _LeagueTrophyDetailDialog(trophy: trophy),
  );
}

class _LeagueTrophyDetailDialog extends StatefulWidget {
  const _LeagueTrophyDetailDialog({required this.trophy});

  final LeagueTrophy trophy;

  @override
  State<_LeagueTrophyDetailDialog> createState() => _LeagueTrophyDetailDialogState();
}

class _LeagueTrophyDetailDialogState extends State<_LeagueTrophyDetailDialog> {
  late final _confettiController = ConfettiController(duration: const Duration(seconds: 2));

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
                  trophy.themeTitle,
                  textAlign: TextAlign.center,
                  style: appHeadlineStyle(fontSize: 22, color: kNavyColor, italic: true),
                ),
                const SizedBox(height: 8),
                Text(
                  trophy.themeDescription,
                  textAlign: TextAlign.center,
                  style: appBodyStyle(fontSize: 14, color: kMutedColor),
                ),
                const SizedBox(height: 12),
                if (trophy.photoUrl.isNotEmpty)
                  MuseumFrame(
                    radius: 8,
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: CachedNetworkImage(imageUrl: trophy.photoUrl, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kGoldColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Won with ★ ${trophy.stars}',
                    style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kNavyColor),
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
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Close',
                      style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
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
                color: kNavyColor,
                border: Border.all(color: kGoldColor, width: 1.5),
              ),
              alignment: Alignment.center,
              child: const AppIcon(AppIcons.trophy, size: 34, color: kGoldColor, strokeWidth: 1.5),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 20,
            maxBlastForce: 16,
            minBlastForce: 6,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [Colors.white, kAccentColor, kGoldColor, kNavyColor, Colors.lightBlueAccent],
          ),
        ],
      ),
    );
  }
}
