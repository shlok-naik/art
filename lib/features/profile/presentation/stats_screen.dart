import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../feed/providers.dart';
import '../domain/stat_key.dart';
import '../providers.dart';

// League standing has no backing data yet — it needs the future league
// feature — so it stays a fixed placeholder like it does on the owner's
// main Profile tab.
const _leagueRank = '#3';

String _formatCount(num count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

String _formatMinutes(double minutes) {
  final hours = minutes ~/ 60;
  final mins = (minutes % 60).round();
  if (hours > 0) return '${hours}h ${mins}m';
  return '${mins}m';
}

/// Public-facing Stats page for one user — reachable from their profile.
/// Only shows the stats the profile owner has opted into via
/// [StatsVisibilityScreen], resolved against real data (posts, followers,
/// views, time spent, streak); league rank remains a hardcoded placeholder.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'Stats'),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Profile not found.', style: GoogleFonts.chewy(fontSize: 16, color: Colors.black)),
              );
            }
            final visibleKeys = statKeysFromStorage(profile.visibleStats);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${profile.username}',
                    style: GoogleFonts.rubikMonoOne(fontSize: 16, color: kAccentColor),
                  ),
                  const SizedBox(height: 2),
                  Text(profile.displayName, style: GoogleFonts.chewy(fontSize: 22, color: Colors.black)),
                  const SizedBox(height: 20),
                  if (visibleKeys.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: appHardCardDecoration(radius: 18),
                      child: Text(
                        "This artist hasn't chosen to show any stats yet.",
                        textAlign: TextAlign.center,
                        style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                      ),
                    )
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        for (final key in visibleKeys) _StatTile(statKey: key, userId: userId),
                      ],
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AppErrorText('Error: $error'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends ConsumerWidget {
  const _StatTile({required this.statKey, required this.userId});

  final StatKey statKey;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(userPostsProvider(userId)).value;
    final followCounts = ref.watch(followCountsProvider(userId)).value;
    final sessionStats = ref.watch(sessionStatsProvider(userId)).value;

    final displayValue = switch (statKey) {
      StatKey.posts => posts == null ? '—' : _formatCount(posts.length),
      StatKey.followers => followCounts == null ? '—' : _formatCount(followCounts.followers),
      StatKey.following => followCounts == null ? '—' : _formatCount(followCounts.following),
      StatKey.totalViews =>
        posts == null ? '—' : _formatCount(posts.fold<int>(0, (sum, post) => sum + post.views)),
      StatKey.timeSpent => sessionStats == null ? '—' : _formatMinutes(sessionStats.totalMinutes),
      StatKey.sessionCount => sessionStats == null ? '—' : _formatCount(sessionStats.sessionCount),
      StatKey.streak => sessionStats == null ? '—' : _formatCount(sessionStats.currentStreakDays),
      StatKey.leagueRank => _leagueRank,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statKey.icon, size: 20, color: kAccentColor),
          const SizedBox(height: 8),
          Text(displayValue, style: appBodyStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 2),
          Text(
            statKey.label,
            style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}
