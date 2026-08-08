import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/formatters.dart';
import '../../achievements/domain/achievement.dart';
import '../../achievements/presentation/achievement_chip.dart';
import '../../achievements/presentation/all_achievements_screen.dart';
import '../../achievements/providers.dart';
import '../../auth/providers.dart';
import '../../feed/providers.dart';
import '../../league/presentation/league_trophy_chip.dart';
import '../../league/presentation/trophy_cabinet_screen.dart';
import '../../league/providers.dart';
import '../providers.dart';
import 'edit_profile_screen.dart';
import 'public_profile_screen.dart';

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
                child: Text('No profile found.', style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              );
            }
            final postsCount = ref.watch(myPostsProvider).value?.length;
            final followersCount = ref.watch(followCountsProvider(profile.id)).value?.followers;
            final leagueRank = ref.watch(leagueRankProvider(profile.id)).value;
            final streakDays = ref.watch(sessionStatsProvider(profile.id)).value?.currentStreakDays ?? 0;
            final unlockedAchievements = ref.watch(unlockedAchievementsProvider(profile.id)).value;
            final leagueTrophies = ref.watch(myLeagueTrophiesProvider(profile.id)).value;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Profile', style: appBodyStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                      InkWell(
                        onTap: () => ref.read(authRepositoryProvider).signOut(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Log out',
                            style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: appFlatCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppInitialsAvatar(name: profile.displayName, size: 72, color: kNavyColor),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    profile.displayName,
                                    style: appBodyStyle(fontSize: 20),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${profile.username}',
                                    style: appBodyStyle(fontSize: 14, color: kMutedColor),
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
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const AppIcon(AppIcons.pencil, size: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: AppStatColumn(
                                value: postsCount == null ? '—' : formatCount(postsCount),
                                label: 'Posts',
                              ),
                            ),
                            Container(width: 1, height: 28, color: kHairlineColor),
                            Expanded(
                              child: AppStatColumn(
                                value: followersCount == null ? '—' : formatCount(followersCount),
                                label: 'Followers',
                              ),
                            ),
                            Container(width: 1, height: 28, color: kHairlineColor),
                            Expanded(
                              child: AppStatColumn(
                                value: leagueRank == null ? '—' : '#$leagueRank',
                                label: 'League rank',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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
                        color: kSurfaceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppIcon(AppIcons.eye, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Preview public profile',
                            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      AppIcon(
                        AppIcons.flame,
                        size: 18,
                        color: streakDays > 0 ? kAccentColor : kMutedColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        streakDays > 0 ? '$streakDays-day streak!' : 'No active streak',
                        style: appBodyStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: streakDays > 0 ? kAccentColor : kInkColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streakDays > 0
                        ? "You're on fire — keep posting to grow your rank."
                        : 'Log a session today to start a streak.',
                    style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMutedColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Achievements', style: appBodyStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(
                        '${unlockedAchievements?.length ?? 0}/${achievementCatalog.length}',
                        style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kMutedColor),
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
                            style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAccentColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (unlockedAchievements == null || unlockedAchievements.isEmpty)
                    Text(
                      'No achievements yet — keep creating to earn your first one.',
                      style: appBodyStyle(fontSize: 13, color: kMutedColor),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Trophy Cabinet', style: appBodyStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(
                        '${leagueTrophies?.length ?? 0}',
                        style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kMutedColor),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => TrophyCabinetScreen(userId: profile.id)),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            'View all',
                            style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAccentColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (leagueTrophies == null || leagueTrophies.isEmpty)
                    Text(
                      "No trophies yet — top the weekly league's leaderboard to win one.",
                      style: appBodyStyle(fontSize: 13, color: kMutedColor),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final trophy in leagueTrophies) LeagueTrophyChip(trophy: trophy),
                      ],
                    ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AppErrorState(
            error: error,
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
        ),
      ),
    );
  }
}


