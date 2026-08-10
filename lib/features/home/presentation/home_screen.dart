import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../../shared/formatters.dart';
import '../../analytics/presentation/analytics_screen.dart';
import '../../feed/domain/feed_post.dart';
import '../../feed/providers.dart';
import '../../league/presentation/league_screen.dart';
import '../../league/providers.dart';
import '../../posts/presentation/my_posts_screen.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../../profile/providers.dart';
import '../../projects/presentation/project_detail_screen.dart';
import '../../projects/presentation/projects_screen.dart';
import '../../projects/providers.dart';
import '../../pro/presentation/pro_screen.dart';
import '../../pro/providers.dart';

const _sidePadding = EdgeInsets.symmetric(horizontal: 16);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final username = profile?.username ?? 'user';
    final streakDays =
        profile == null ? 0 : ref.watch(sessionStatsProvider(profile.id)).value?.currentStreakDays ?? 0;

    final lastProject = ref.watch(lastOpenedProjectProvider).value;
    final lastProjectCompletion =
        int.tryParse(lastProject?['completion_percent']?.toString() ?? '') ?? 0;
    // The league submit picker already pairs each of the user's projects
    // with its latest session photo — reused here for the hero card thumbnail.
    final projectCovers = ref.watch(myProjectsWithCoverProvider).value;
    String? heroPhotoUrl;
    if (lastProject != null && projectCovers != null) {
      for (final (project, cover) in projectCovers) {
        if (project['id'].toString() == lastProject['id'].toString()) {
          heroPhotoUrl = cover;
          break;
        }
      }
    }

    final myPosts = ref.watch(myPostsProvider).value ?? const <FeedPost>[];
    final mostRecentPost = myPosts.isEmpty ? null : myPosts.first;
    final mostRecentReactionsTotal = mostRecentPost == null
        ? 0
        : ref.watch(sessionReactionsProvider(mostRecentPost.id)).value?.total ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: _sidePadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Image.asset(
                              'assets/branding/logo.png',
                              height: 44,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _BuyProPill(
                            isPro: ref.watch(isProProvider),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProScreen()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: _sidePadding,
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickActionChip(
                              emoji: '🏆',
                              label: 'League',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LeagueScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickActionChip(
                              emoji: '📊',
                              label: 'Analytics',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickActionChip(
                              emoji: '🖼️',
                              label: 'My Posts',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickActionChip(
                              emoji: '📁',
                              label: 'Projects',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProjectsScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: _sidePadding,
                      child: Center(
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'WELCOME',
                                maxLines: 1,
                                softWrap: false,
                                style: GoogleFonts.chewy(
                                  fontSize: 68,
                                  letterSpacing: 1,
                                  height: 1.0,
                                  color: kAccentColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@$username',
                              style: GoogleFonts.rubikMonoOne(fontSize: 30, color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ready to create a masterpiece?',
                              style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF444444)),
                              textAlign: TextAlign.center,
                            ),
                            if (streakDays > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kAccentTintColor,
                                  border: Border.all(color: kBorderColor, width: kBorderWidth),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$streakDays day streak',
                                      style: GoogleFonts.chewy(fontSize: 13, color: kAccentColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: _sidePadding,
                      child: InkWell(
                        onTap: lastProject == null
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: lastProject)),
                              ),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: appHardCardDecoration(radius: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  if (heroPhotoUrl case final photoUrl?
                                      when photoUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CachedNetworkImage(
                                        imageUrl: photoUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: kAccentColor,
                                            border: Border.all(color: kBorderColor, width: kBorderWidth),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: kAccentColor,
                                        border: Border.all(color: kBorderColor, width: kBorderWidth),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
                                    ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Continue Last Project',
                                          style: GoogleFonts.chewy(fontSize: 18, color: Colors.black),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          lastProject == null
                                              ? 'Start a project to see it here'
                                              : (lastProject['title']?.toString() ?? lastProject['id'].toString()),
                                          style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF555555)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (lastProject != null) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    height: 8,
                                    color: const Color(0xFFF0EDE8),
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: lastProjectCompletion / 100,
                                      child: Container(color: kAccentColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$lastProjectCompletion% complete',
                                  style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kAccentColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: _sidePadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              'Most Recent Post',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.chewy(fontSize: 18, color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                            ),
                            child: Text(
                              'See all',
                              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kAccentColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: _sidePadding,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: mostRecentPost == null
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PostDetailScreen(post: mostRecentPost)),
                              ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: appHardCardDecoration(radius: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 130,
                                      width: double.infinity,
                                      color: Colors.grey.shade200,
                                      child: (mostRecentPost?.photoUrl == null || mostRecentPost!.photoUrl!.isEmpty)
                                          ? Center(
                                              child: Text(
                                                mostRecentPost == null ? 'No posts yet' : 'Image',
                                                style: GoogleFonts.chewy(
                                                  fontSize: mostRecentPost == null ? 18 : 44,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: mostRecentPost.photoUrl!,
                                              fit: BoxFit.cover,
                                              errorWidget: (context, url, error) => const Center(
                                                child: Icon(Icons.image_not_supported, size: 40, color: Colors.black38),
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (mostRecentPost != null)
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.72),
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.favorite, size: 14, color: Colors.white),
                                            const SizedBox(width: 5),
                                            Text(
                                              '$mostRecentReactionsTotal',
                                              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                mostRecentPost?.displayTitle ?? 'No recent posts',
                                style: GoogleFonts.chewy(fontSize: 16, color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mostRecentPost == null
                                    ? 'Finish a session to see it here.'
                                    : '👁 ${mostRecentPost.views} views     🗓 ${formatMonthDayYear(mostRecentPost.datePosted)}',
                                style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF666666)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyProPill extends StatelessWidget {
  const _BuyProPill({required this.isPro, required this.onPressed});

  final bool isPro;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: kAccentColor,
          border: Border.all(color: kBorderColor, width: kBorderWidth),
          borderRadius: BorderRadius.circular(20),
          boxShadow: hardShadow(offset: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(isPro ? 'Pro' : 'Buy Pro', style: GoogleFonts.chewy(fontSize: 15, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.emoji, required this.label, required this.onPressed});

  final String emoji;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.chewy(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
