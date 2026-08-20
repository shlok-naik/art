import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../../profile/presentation/public_profile_screen.dart';
import '../../profile/providers.dart';
import '../../projects/providers.dart';
import '../domain/feed_post.dart';
import '../domain/reactions.dart';
import '../providers.dart';
import 'comments_sheet.dart';

/// Scrollable card feed: one bordered comic-panel card per post
/// (avatar/handle/follow, square photo, heart + comment row, caption).
/// Only a single heart reaction is exposed here — no thumbs-down, no emoji
/// picker; the full reaction breakdown still lives on [PostDetailScreen].
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedPostsProvider);

    return Scaffold(
      appBar: appThemedAppBar(context, 'Feed'),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Text(
                'No posts yet — finish a session to see it here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.chewy(fontSize: 16, color: kInkColor),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            itemCount: posts.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _FeedPostCard(post: posts[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          error: error,
          onRetry: () => ref.invalidate(feedPostsProvider),
        ),
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
  String get _sessionId => widget.post.id;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the card entering the tree records one aggregate view.
    ref.read(sessionsRepositoryProvider).recordView(_sessionId);
  }

  /// Fires the optimistic like and returns immediately — the provider
  /// updates state synchronously, so the UI reflects the tap before the
  /// network write completes. Failures revert the state and surface here.
  void _toggleLike() {
    ref
        .read(sessionReactionsProvider(_sessionId).notifier)
        .react('up')
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

  void _openDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: widget.post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final reactions =
        ref.watch(sessionReactionsProvider(_sessionId)).value ?? SessionReactions.empty;
    final likeCount = reactions.counts['up'] ?? 0;
    final isLiked = reactions.myVote?['reaction_type']?.toString() == 'up';
    final commentCount = ref.watch(sessionCommentsProvider(_sessionId)).value?.length ?? 0;
    final myUserId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final isMine = post.userId == myUserId;
    final isFollowing = ref.watch(isFollowingProvider(post.userId)).value ?? false;

    return Container(
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: post.userId)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kBorderColor, width: kBorderWidth),
                          ),
                          child: AppInitialsAvatar(
                            name: post.artist,
                            size: 36,
                            imageUrl: post.artistAvatarUrl,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '@${post.artist}',
                                style: GoogleFonts.chewy(fontSize: 15, color: kInkColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                post.type == FeedPostType.slideshow ? 'slideshow' : 'session',
                                style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMutedColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isMine) ...[
                  const SizedBox(width: 8),
                  _FollowPill(userId: post.userId, isFollowing: isFollowing),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: _openDetail,
            child: AspectRatio(
              aspectRatio: 1,
              child: _PostImage(post: post),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                InkWell(
                  onTap: _toggleLike,
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 26,
                    color: isLiked ? kAccentColor : kInkColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$likeCount',
                  style: GoogleFonts.chewy(fontSize: 14, color: kInkColor),
                ),
                const SizedBox(width: 18),
                InkWell(
                  onTap: _showComments,
                  child: Icon(Icons.mode_comment_outlined, size: 24, color: kInkColor),
                ),
                const SizedBox(width: 6),
                Text(
                  '$commentCount',
                  style: GoogleFonts.chewy(fontSize: 14, color: kInkColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              '${post.artist} — ${post.displayTitle}',
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInkColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Text(
          'Image',
          style: GoogleFonts.chewy(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.black38),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: photoUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.grey.shade100),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.black38),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? kAccentTintColor : kAccentColor,
          border: Border.all(color: kBorderColor, width: kBorderWidth),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: GoogleFonts.chewy(
            fontSize: 12,
            color: isFollowing ? kInkColor : Colors.white,
          ),
        ),
      ),
    );
  }
}
