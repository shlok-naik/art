import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../auth/providers.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../profile/providers.dart';
import '../../projects/providers.dart';
import '../domain/feed_post.dart';
import '../domain/reactions.dart';
import '../providers.dart';
import 'comments_sheet.dart';

/// Scrollable Instagram-style card feed: navy header bar, then one bordered
/// card per post (avatar/handle/follow, square photo, heart-comment-share
/// action row, likes + caption). Replaces the old full-screen vertical
/// swipe (Reels-style) layout.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedPostsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: kHairlineColor, width: 1)),
            ),
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Feed',
                      style: appBodyStyle(fontSize: 20, fontWeight: FontWeight.w600)
                          .copyWith(letterSpacing: 0.2),
                    ),
                  ),
                  const AppIcon(AppIcons.search, color: kInkColor, strokeWidth: 2),
                  const SizedBox(width: AppSpacing.space16),
                  const AppIcon(AppIcons.bell, color: kInkColor, strokeWidth: 2),
                ],
              ),
            ),
          ),
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Text(
                      'No posts yet — finish a session to see it here.',
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 14, color: kMutedColor),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) => _FeedPostCard(post: posts[index]),
                );
              },
              loading: () => const AppSkeletonScreen(),
              error: (error, _) => AppErrorState(
                error: error,
                onRetry: () => ref.invalidate(feedPostsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedPostCard extends ConsumerStatefulWidget {
  const _FeedPostCard({required this.post});

  final FeedPost post;

  @override
  ConsumerState<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends ConsumerState<_FeedPostCard> {
  int _slideIndex = 0;

  String get _sessionId => widget.post.id;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the card entering the tree records one aggregate view.
    ref.read(sessionsRepositoryProvider).recordView(_sessionId);
  }

  /// Fires the optimistic reaction and returns immediately — the provider
  /// updates state synchronously, so the UI reflects the tap before the
  /// network write completes. Failures revert the state and surface here.
  void _react(String reactionType) {
    ref
        .read(sessionReactionsProvider(_sessionId).notifier)
        .react(reactionType)
        .catchError((Object e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to react: $e')),
      );
    });
  }

  void _showComments() {
    showCommentsSheet(context, sessionId: _sessionId, postOwnerUserId: widget.post.userId);
  }

  void _showDetails() {
    final post = widget.post;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.space16),
                  decoration: BoxDecoration(
                    color: kHairlineColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text('Title', style: appBodyStyle(fontSize: 12, color: kMutedColor)),
              Text(post.displayTitle, style: appBodyStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space16),
              Row(
                children: [
                  Expanded(child: AppDetailStat(label: 'Views', value: formatCount(post.views))),
                  Expanded(
                    child: AppDetailStat(
                      label: 'Date posted',
                      value: formatMonthDayYear(post.datePosted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space20),
              Text('Details', style: appBodyStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space8),
              Text(post.description, style: appBodyStyle(fontSize: 14)),
              const SizedBox(height: AppSpacing.space12),
              Text('Tools used', style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tool in post.toolsUsed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space8),
                      decoration: BoxDecoration(
                        color: kSurfaceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(tool, style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space12),
              Text('Time taken', style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.space4),
              Text(post.timeTaken, style: appBodyStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final reactions =
        ref.watch(sessionReactionsProvider(_sessionId)).value ?? SessionReactions.empty;
    final likeCount = reactions.counts['up'] ?? 0;
    final isLiked = reactions.myVote?['reaction_type']?.toString() == 'up';
    final myUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final isMine = post.userId == myUserId;
    final isFollowing = ref.watch(isFollowingProvider(post.userId)).value ?? false;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kHairlineColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: post.userId)),
                    ),
                    child: Row(
                      children: [
                        AppInitialsAvatar(name: post.artist, size: 38),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                post.artist,
                                style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                post.type == FeedPostType.slideshow ? 'slideshow' : 'session',
                                style: appBodyStyle(fontSize: 12, color: kMutedColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isMine) ...[
                  const SizedBox(width: AppSpacing.space8),
                  _FollowPill(userId: post.userId, isFollowing: isFollowing),
                ],
              ],
            ),
          ),
          // Inset rather than edge-to-edge so the photo reads as a framed
          // piece hung inside the card.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 5, 14, 0),
            child: MuseumFrame(
              radius: 10,
              child: AspectRatio(
                aspectRatio: 1,
                child: post.slideCount > 1
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            itemCount: post.slideCount,
                            onPageChanged: (index) => setState(() => _slideIndex = index),
                            itemBuilder: (context, index) => _PostImage(post: post),
                          ),
                          Positioned(
                            top: 8,
                            left: 12,
                            right: 12,
                            child: _SlideIndicator(count: post.slideCount, current: _slideIndex),
                          ),
                        ],
                      )
                    : _PostImage(post: post),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _react('up'),
                  child: isLiked
                      ? const AppIcon(AppIcons.heartFilled, size: 24, color: kAccentColor)
                      : const AppIcon(AppIcons.heart, size: 24),
                ),
                const SizedBox(width: AppSpacing.space16),
                InkWell(onTap: _showComments, child: const AppIcon(AppIcons.comment, size: 24)),
                const SizedBox(width: AppSpacing.space16),
                // The paper plane surfaces the post's details sheet — the
                // closest existing behavior to "share" (the old more-vert
                // target); a real OS share sheet is a separate feature.
                InkWell(onTap: _showDetails, child: const AppIcon(AppIcons.share, size: 24)),
              ],
            ),
          ),
          // Museum wall label: navy plaque with a gold edge, the gold like
          // count above the artist/title set in italic Fraunces.
          Container(
            margin: const EdgeInsets.fromLTRB(14, 2, 14, 12),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12, vertical: AppSpacing.space12),
            decoration: const BoxDecoration(
              color: kNavyColor,
              borderRadius: BorderRadius.all(Radius.circular(6)),
              border: Border(left: BorderSide(color: kGoldColor, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon(AppIcons.heartFilled, size: 12, color: kGoldColor),
                    const SizedBox(width: AppSpacing.space4),
                    Text(
                      '$likeCount LIKES',
                      style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kGoldColor)
                          .copyWith(letterSpacing: 0.66),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '${post.artist} — ${post.displayTitle}',
                  style: appHeadlineStyle(fontSize: 14, color: Colors.white, italic: true),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final photoUrl = post.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        color: kSurfaceColor,
        alignment: Alignment.center,
        child: Text('Image', style: appBodyStyle(fontSize: 12, color: kMutedColor)),
      );
    }
    return CachedNetworkImage(
      imageUrl: photoUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: kSurfaceColor),
      errorWidget: (context, url, error) => Container(
        color: kSurfaceColor,
        alignment: Alignment.center,
        child: const AppIcon(AppIcons.image, size: 40, color: kMutedColor),
      ),
    );
  }
}

/// Cobalt "Follow" / flat "Following" pill with the same optimistic-feeling
/// flow as the Followed screen: writes through FollowsRepository, then
/// invalidates the follow providers so every screen agrees.
class _FollowPill extends ConsumerStatefulWidget {
  const _FollowPill({required this.userId, required this.isFollowing});

  final String userId;
  final bool isFollowing;

  @override
  ConsumerState<_FollowPill> createState() => _FollowPillState();
}

class _FollowPillState extends ConsumerState<_FollowPill> {
  bool _isBusy = false;

  Future<void> _toggle() async {
    setState(() => _isBusy = true);
    try {
      final repo = ref.read(followsRepositoryProvider);
      if (widget.isFollowing) {
        await repo.unfollow(widget.userId);
      } else {
        await repo.follow(widget.userId);
      }
      ref.invalidate(isFollowingProvider(widget.userId));
      ref.invalidate(followingListProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowing = widget.isFollowing;
    return InkWell(
      onTap: _isBusy ? null : _toggle,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space8),
        decoration: BoxDecoration(
          color: isFollowing ? kSurfaceColor : kAccentColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: appBodyStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isFollowing ? kInkColor : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SlideIndicator extends StatelessWidget {
  const _SlideIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i == count - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: i <= current ? kAccentColor : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}
