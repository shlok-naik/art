import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../../feed/providers.dart';
import '../providers.dart';
import 'edit_profile_screen.dart';

// League rank and streak have no backing data yet — league standing needs
// the future league feature, and streaks need day-over-day session-date
// tracking that doesn't exist. Posts and Followers below are real.
const _leagueRank = '#3';
const _streakDays = 7;

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

const _achievements = [
  {'emoji': '🥇', 'label': 'Top 10', 'locked': false},
  {'emoji': '🎨', 'label': '50 Posts', 'locked': false},
  {'emoji': '⚡', 'label': 'Streak 7', 'locked': false},
  {'emoji': '🔒', 'label': '???', 'locked': true},
];

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
                            Flexible(
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
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: appHardCardDecoration(radius: 18, color: kAccentTintColor),
                    child: Row(
                      children: [
                        Image.asset('assets/branding/mascot.png', height: 56),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$_streakDays-day streak! 🔥', style: GoogleFonts.chewy(fontSize: 17, color: Colors.black)),
                              const SizedBox(height: 2),
                              Text(
                                "You're on fire — keep posting to grow your rank.",
                                style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF555555)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Achievements', style: GoogleFonts.chewy(fontSize: 18, color: Colors.black)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final achievement in _achievements)
                        _AchievementChip(
                          emoji: achievement['emoji'] as String,
                          label: achievement['label'] as String,
                          locked: achievement['locked'] as bool,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color.fromARGB(255, 228, 91, 12), width: kBorderWidth),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: hardShadow(offset: 3),
                      ),
                      alignment: Alignment.center,
                      child: Text('Edit Profile', style: GoogleFonts.chewy(fontSize: 16, color: const Color.fromARGB(255, 246, 240, 240))),
                    ),
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

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.emoji, required this.label, required this.locked});

  final String emoji;
  final String label;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: locked
          ? BoxDecoration(
              color: const Color(0xFFF5F5F5),
              border: Border.all(color: const Color(0xFFCCCCCC), width: kBorderWidth),
              borderRadius: BorderRadius.circular(14),
            )
          : appHardCardDecoration(radius: 14, shadowOffset: 2),
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appBodyStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: locked ? const Color(0xFF888888) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
