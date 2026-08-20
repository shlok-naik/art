import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../../shared/formatters.dart';
import '../domain/league.dart';
import '../providers.dart';
import 'league_trophy_chip.dart';

/// Every league [userId] has won, newest first — the full trophy cabinet
/// behind the profile's "View all" link, same relationship
/// [AllAchievementsScreen] has to the achievements chips row.
class TrophyCabinetScreen extends ConsumerWidget {
  const TrophyCabinetScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trophiesAsync = ref.watch(myLeagueTrophiesProvider(userId));

    return Scaffold(
      appBar: appThemedAppBar(context, 'Trophy Cabinet'),
      body: trophiesAsync.when(
        data: (trophies) {
          if (trophies.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "No trophies yet — top the weekly league's leaderboard to win one.",
                  textAlign: TextAlign.center,
                  style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF888888)),
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: trophies.length,
            itemBuilder: (context, index) => _TrophyTile(trophy: trophies[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppErrorState(
          error: error,
          onRetry: () => ref.invalidate(myLeagueTrophiesProvider(userId)),
        ),
      ),
    );
  }
}

class _TrophyTile extends StatelessWidget {
  const _TrophyTile({required this.trophy});

  final LeagueTrophy trophy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showLeagueTrophyDetail(context, trophy: trophy),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: appHardCardDecoration(radius: 14, shadowOffset: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: trophy.photoUrl.isEmpty
                    ? Container(
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.emoji_events, size: 24, color: Colors.black26),
                      )
                    : CachedNetworkImage(
                        imageUrl: trophy.photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(color: Colors.grey.shade100),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.emoji_events, size: 24, color: Colors.black26),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trophy.themeTitle,
              style: GoogleFonts.chewy(fontSize: 14, color: kInkColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              formatMonthDayYear(trophy.startsAt),
              style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: kBorderColor, width: kBorderWidth),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    '${trophy.stars}',
                    style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kInkColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
