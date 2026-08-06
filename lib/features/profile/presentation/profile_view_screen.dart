import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/presentation/achievement_chip.dart';
import '../../achievements/presentation/all_achievements_screen.dart';
import '../../achievements/providers.dart';
import '../../auth/providers.dart';
import '../../feed/providers.dart';
import '../providers.dart';
import 'edit_profile_screen.dart';
import 'public_profile_screen.dart';

// League standing has no backing data yet — it needs the future league
// feature. Posts, Followers, streak, and achievements below are all real.
const _leagueRank = '#3';

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No profile found.', style: GoogleFonts.chewy(fontSize: 16, color: Colors.black)),
              );
            }
            final postsCount = ref.watch(myPostsProvider).value?.length;
            final followersCount = ref.watch(followCountsProvider(profile.id)).value?.followers;
            final streakDays = ref.watch(sessionStatsProvider(profile.id)).value?.currentStreakDays ?? 0;
            final unlockedAchievements = ref.watch(unlockedAchievementsProvider(profile.id)).value;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile', style: GoogleFonts.chewy(fontSize: 24, color: Colors.black)),
                      InkWell(
                        onTap: () => ref.read(authRepositoryProvider).signOut(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: kBorderColor, width: kBorderWidth),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Log out',
                            style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: appHardCardDecoration(radius: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                                border: Border.all(color: kBorderColor, width: kBorderWidth),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.person, size: 36, color: Colors.black26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    profile.displayName,
                                    style: GoogleFonts.chewy(fontSize: 22, color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${profile.username}',
                                    style: GoogleFonts.rubikMonoOne(fontSize: 15, color: kAccentColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: kBorderColor, width: kBorderWidth),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.edit, size: 18, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                value: postsCount == null ? '—' : _formatCount(postsCount),
                                label: 'Posts',
                              ),
                            ),
                            Container(width: 2, height: 32, color: const Color(0xFFEEEEEE)),
                            Expanded(
                              child: _StatColumn(
                                value: followersCount == null ? '—' : _formatCount(followersCount),
                                label: 'Followers',
                              ),
                            ),
                            Container(width: 2, height: 32, color: const Color(0xFFEEEEEE)),
                            Expanded(child: _StatColumn(value: _leagueRank, label: 'League rank')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: profile.id)),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorderColor, width: kBorderWidth),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.remove_red_eye, size: 18, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            'Preview public profile',
                            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    streakDays > 0 ? '$streakDays-day streak! 🔥' : 'No active streak',
                    style: GoogleFonts.chewy(fontSize: 17, color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streakDays > 0
                        ? "You're on fire — keep posting to grow your rank."
                        : 'Log a session today to start a streak.',
                    style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF555555)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Achievements', style: GoogleFonts.chewy(fontSize: 18, color: Colors.black)),
                      const SizedBox(width: 8),
                      Text(
                        '${unlockedAchievements?.length ?? 0}/${achievementCatalog.length}',
                        style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => AllAchievementsScreen(userId: profile.id)),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            'View all',
                            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kAccentColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (unlockedAchievements == null || unlockedAchievements.isEmpty)
                    Text(
                      'No achievements yet — keep creating to earn your first one.',
                      style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF888888)),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final achievement in achievementCatalog)
                          if (unlockedAchievements.containsKey(achievement.key))
                            AchievementChip(achievement: achievement),
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

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
        const SizedBox(height: 2),
        Text(label, style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF888888))),
      ],
    );
  }
}

