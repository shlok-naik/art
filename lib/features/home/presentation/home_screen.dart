import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_icons.dart';
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

String _greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

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
    // with its latest session photo — reused here for the hero card image.
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Scales down rather than wrapping or clipping — on
                        // the narrowest phones the wordmark and the Pro pill
                        // together exceed the row's width.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Unfinished',
                              style: appBodyStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: kNavyColor,
                              ).copyWith(letterSpacing: -0.3),
                            ),
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greetingForNow()}, $username',
                                style: appBodyStyle(fontSize: 22, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ready to create a masterpiece?',
                                style: appBodyStyle(fontSize: 13, color: kMutedColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: kAccentTintColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(AppIcons.flame, size: 14, color: kAccentColor),
                              const SizedBox(width: 5),
                              Text(
                                '$streakDays',
                                style: appBodyStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kAccentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _HeroProjectCard(
                      project: lastProject,
                      completionPercent: lastProjectCompletion,
                      photoUrl: heroPhotoUrl,
                    ),
                    const SizedBox(height: 20),
                    _QuickActionsBar(
                      items: [
                        (AppIcons.trophy, 'League', () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LeagueScreen()))),
                        (AppIcons.barChart, 'Analytics', () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AnalyticsScreen()))),
                        (AppIcons.image, 'My posts', () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyPostsScreen()))),
                        (AppIcons.folder, 'Projects', () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProjectsScreen()))),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            'Recent activity',
                            overflow: TextOverflow.ellipsis,
                            style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                          ),
                          child: Text(
                            'See all',
                            style: appBodyStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kAccentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _RecentActivityRow(
                      post: mostRecentPost,
                      reactionsTotal: mostRecentReactionsTotal,
                    ),
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: kAccentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppIcons.crown, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              isPro ? 'Pro' : 'Buy Pro',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashboard's hero: the last-opened project's photo with a navy scrim,
/// an IN PROGRESS badge, title + progress bar, and a centered cobalt play
/// button. Both the card and the play button open the project, same as the
/// old "Continue last project" tap target.
class _HeroProjectCard extends StatelessWidget {
  const _HeroProjectCard({
    required this.project,
    required this.completionPercent,
    required this.photoUrl,
  });

  final Map<String, dynamic>? project;
  final int completionPercent;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final project = this.project;

    return InkWell(
      onTap: project == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project))),
      borderRadius: BorderRadius.circular(25),
      child: MuseumFrame(
        radius: 20,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photoUrl != null && photoUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: kSurfaceColor),
                  errorWidget: (context, url, error) => const _StripedPlaceholder(),
                )
              else
                const _StripedPlaceholder(),
              // Bottom-to-top navy scrim so the title/progress stay legible
              // over any photo.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0, 0.55, 0.75],
                    colors: [
                      kNavyColor.withValues(alpha: 0.88),
                      kNavyColor.withValues(alpha: 0.25),
                      kNavyColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kNavyColor.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    project == null ? 'NO PROJECT YET' : 'IN PROGRESS',
                    style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)
                        .copyWith(letterSpacing: 0.4),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project == null
                          ? 'Start a project to see it here'
                          : (project['title']?.toString() ?? project['id'].toString()),
                      style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (project != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                height: 6,
                                color: Colors.white.withValues(alpha: 0.28),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: completionPercent / 100,
                                  child: Container(color: kAccentColor),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$completionPercent%',
                            style: appBodyStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (project != null)
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kAccentColor,
                      boxShadow: [
                        BoxShadow(
                          color: kNavyColor.withValues(alpha: 0.35),
                          offset: const Offset(0, 6),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const AppIcon(AppIcons.play, size: 20, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripedPlaceholder extends StatelessWidget {
  const _StripedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StripePainter());
  }
}

/// Diagonal-stripe placeholder matching the prototypes' repeating-gradient
/// stand-in for a missing photo.
class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEDEFF4));
    final stripe = Paint()..color = const Color(0xFFE2E6EF);
    const width = 14.0;
    for (var x = -size.height; x < size.width; x += width * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + width, 0)
        ..lineTo(x + width, size.height)
        ..close();
      canvas.drawPath(path, stripe);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) => false;
}

/// One continuous surface strip of four equal tappable columns separated by
/// hairline dividers.
class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar({required this.items});

  final List<(String icon, String label, VoidCallback onTap)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appFlatCardDecoration(),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: VerticalDivider(width: 1, thickness: 1, color: kHairlineColor),
                ),
              Expanded(
                child: InkWell(
                  onTap: items[i].$3,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(items[i].$1, size: 18),
                        const SizedBox(height: 6),
                        Text(
                          items[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.post, required this.reactionsTotal});

  final FeedPost? post;
  final int reactionsTotal;

  @override
  Widget build(BuildContext context) {
    final post = this.post;
    if (post == null) {
      return Text(
        'No posts yet — finish a session to see it here.',
        style: appBodyStyle(fontSize: 13, color: kMutedColor),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: (post.photoUrl == null || post.photoUrl!.isEmpty)
                  ? const _StripedPlaceholder()
                  : CachedNetworkImage(
                      imageUrl: post.photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const _StripedPlaceholder(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  post.displayTitle,
                  style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const AppIcon(AppIcons.eye, size: 13, color: kMutedColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${formatCount(post.views)} views · ${formatShortMonthDay(post.datePosted)}',
                        style: appBodyStyle(fontSize: 12, color: kMutedColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const AppIcon(AppIcons.heartFilled, size: 15, color: kGoldColor),
          const SizedBox(width: 4),
          Text(
            '$reactionsTotal',
            style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kGoldColor),
          ),
        ],
      ),
    );
  }
}
