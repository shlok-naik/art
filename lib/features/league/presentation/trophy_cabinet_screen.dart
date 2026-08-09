import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_icons.dart';
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
      backgroundColor: Colors.white,
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
                  style: appBodyStyle(fontSize: 14, color: kMutedColor),
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
      // The whole tile is the navy mat: gold-hairlined photo above the
      // trophy's title, date and star pill.
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: kNavyColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: kGoldColor, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: trophy.photoUrl.isEmpty
                    ? const _MissingTrophyPhoto()
                    : CachedNetworkImage(
                        imageUrl: trophy.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: kSurfaceColor),
                        errorWidget: (context, url, error) => const _MissingTrophyPhoto(),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trophy.themeTitle,
              style: appHeadlineStyle(fontSize: 15, color: Colors.white, italic: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              formatMonthDayYear(trophy.startsAt),
              style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGoldColor),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: kGoldColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '★ ${trophy.stars}',
                textAlign: TextAlign.center,
                style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kNavyColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingTrophyPhoto extends StatelessWidget {
  const _MissingTrophyPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurfaceColor,
      alignment: Alignment.center,
      child: const AppIcon(AppIcons.trophy, size: 24, color: kMutedColor),
    );
  }
}
