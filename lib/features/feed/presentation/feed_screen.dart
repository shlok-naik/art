import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../profile/providers.dart';
import '../../projects/providers.dart';
import '../../shell/main_shell.dart';
import '../domain/feed_post.dart';
import '../domain/reactions.dart';
import '../providers.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return count.toString();
}

/// Full-screen scrollable feed of posted slideshows and sessions, styled
/// like YT Shorts / Instagram Reels: vertical swipe between posts, and
/// (for slideshows) horizontal swipe through a post's slide photos. The
/// vertical feed loops — swiping past the last post wraps back to the first.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedPostsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Text(
                'No posts yet — finish a session to see it here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.chewy(color: Colors.white, fontSize: 16),
              ),
            );
          }
          // No itemCount: the builder is unbounded, so the feed never
          // dead-ends — indexes wrap back onto the post list.
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) =>
                _FeedPostCard(post: posts[index % posts.length]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (error, _) => Center(
          child: Text(
            'Failed to load feed: $error',
            textAlign: TextAlign.center,
            style: GoogleFonts.chewy(color: Colors.white, fontSize: 16),
          ),
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
  int _slideIndex = 0;

  String get _sessionId => widget.post.id;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: the card entering the tree is the view event. The
    // (session_id, viewer_id) upsert on the server means repeat views by
    // the same viewer are a silent no-op, not double-counted.
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

  void _showDetails() {
    final post = widget.post;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DefaultTextStyle(
        style: GoogleFonts.chewy(color: Colors.black),
        child: SafeArea(
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
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'Title',
                  style: GoogleFonts.chewy(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  post.displayTitle,
                  style: GoogleFonts.chewy(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DetailStat(
                        icon: Icons.visibility_outlined,
                        label: 'Views',
                        value: _formatCount(post.views),
                      ),
                    ),
                    Expanded(
                      child: _DetailStat(
                        icon: Icons.event_outlined,
                        label: 'Date posted',
                        value: _formatDate(post.datePosted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Details',
                  style: GoogleFonts.chewy(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(post.description, style: GoogleFonts.chewy(fontSize: 15)),
                const SizedBox(height: 12),
                Text(
                  'Tools used',
                  style: GoogleFonts.chewy(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tool in post.toolsUsed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: kBorderColor,
                            width: kBorderWidth,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tool,
                          style: GoogleFonts.chewy(fontSize: 14),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Time taken',
                  style: GoogleFonts.chewy(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(post.timeTaken, style: GoogleFonts.chewy(fontSize: 15)),
              ],
            ),
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
    final counts = reactions.counts;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: post.slideCount,
          onPageChanged: (index) => setState(() => _slideIndex = index),
          itemBuilder: (context, index) {
            final photoUrl = post.photoUrl;
            if (photoUrl == null || photoUrl.isEmpty) {
              return Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: Text(
                  'Image',
                  style: GoogleFonts.chewy(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                  ),
                ),
              );
            }
            return CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey.shade900),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 54, color: Colors.black38),
              ),
            );
          },
        ),
        // Bottom gradient scrim so the caption/actions stay legible over any
        // photo, instead of relying on plain text-shadows alone.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 280,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.78)],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              children: [
                if (post.slideCount > 1)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _SlideIndicator(
                      count: post.slideCount,
                      current: _slideIndex,
                    ),
                  ),
                Positioned(
                  top: post.slideCount > 1 ? 14 : 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () => goToMainTab(context, ref, 0),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kAccentColor,
                        border: Border.all(
                          color: kBorderColor,
                          width: kBorderWidth,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  right: 76,
                  bottom: 78,
                  child: _PostCaption(post: post),
                ),
                Positioned(
                  right: 4,
                  bottom: 78,
                  child: _RightActionColumn(
                    upCount: counts['up'] ?? 0,
                    downCount: counts['down'] ?? 0,
                    onThumbUp: () => _react('up'),
                    onThumbDown: () => _react('down'),
                    onMore: _showDetails,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _EmojiReactionRow(
                    counts: {
                      for (final reaction in EmojiReaction.values)
                        reaction: counts[reaction.name] ?? 0,
                    },
                    onSelect: (reaction) => _react(reaction.name),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PostCaption extends ConsumerWidget {
  const _PostCaption({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(isFollowingProvider(post.userId)).value ?? false;

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: kAccentColor,
              border: Border.all(color: kBorderColor, width: kBorderWidth),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              post.type == FeedPostType.slideshow ? 'SLIDESHOW' : 'SESSION',
              style: GoogleFonts.chewy(fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '@${post.artist}',
                style: GoogleFonts.chewy(fontSize: 19, shadows: _shadow),
              ),
              if (isFollowing) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    border: Border.all(color: Colors.white, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Following',
                    style: GoogleFonts.chewy(fontSize: 11, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            post.displayTitle,
            style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)
                .copyWith(shadows: _shadow),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

const _shadow = [Shadow(color: Colors.black54, blurRadius: 6)];

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
                color: i <= current
                    ? kAccentColor
                    : Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _RightActionColumn extends StatelessWidget {
  const _RightActionColumn({
    required this.upCount,
    required this.downCount,
    required this.onThumbUp,
    required this.onThumbDown,
    required this.onMore,
  });

  final int upCount;
  final int downCount;
  final VoidCallback onThumbUp;
  final VoidCallback onThumbDown;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReactionEmoji(
          glyph: '👍',
          onTap: onThumbUp,
          baseSize: 64,
        ),
        Text(
          _formatCount(upCount),
          style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)
              .copyWith(shadows: _shadow),
        ),
        const SizedBox(height: 18),
        _ReactionEmoji(
          glyph: '👎',
          onTap: onThumbDown,
          baseSize: 64,
        ),
        Text(
          _formatCount(downCount),
          style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)
              .copyWith(shadows: _shadow),
        ),
        const SizedBox(height: 16),
        _CircleIconButton(icon: Icons.more_vert, onTap: onMore),
      ],
    );
  }
}

class _EmojiReactionRow extends StatelessWidget {
  const _EmojiReactionRow({
    required this.counts,
    required this.onSelect,
  });

  final Map<EmojiReaction, int> counts;
  final ValueChanged<EmojiReaction> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final reaction in EmojiReaction.values)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReactionEmoji(
                glyph: emojiGlyphs[reaction]!,
                onTap: () => onSelect(reaction),
                baseSize: 48,
              ),
              const SizedBox(height: 3),
              Text(
                _formatCount(counts[reaction]!),
                style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)
                    .copyWith(shadows: _shadow),
              ),
            ],
          ),
      ],
    );
  }
}

/// A floating emoji reaction button — no background chip, just the glyph
/// itself (with a soft drop shadow for legibility over any photo). Tapping
/// gives it a springy overshoot-and-settle bounce.
class _ReactionEmoji extends StatefulWidget {
  const _ReactionEmoji({
    required this.glyph,
    required this.onTap,
    this.baseSize = 40,
  });

  final String glyph;
  final VoidCallback onTap;
  final double baseSize;

  @override
  State<_ReactionEmoji> createState() => _ReactionEmojiState();
}

class _ReactionEmojiState extends State<_ReactionEmoji> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final _bounce = TweenSequence<double>([
    TweenSequenceItem(weight: 30, tween: Tween(begin: 1.0, end: 1.5).chain(CurveTween(curve: Curves.easeOut))),
    TweenSequenceItem(weight: 20, tween: Tween(begin: 1.5, end: 0.85).chain(CurveTween(curve: Curves.easeInOut))),
    TweenSequenceItem(weight: 50, tween: Tween(begin: 0.85, end: 1.0).chain(CurveTween(curve: Curves.elasticOut))),
  ]).animate(_controller);
  late final _wiggle = TweenSequence<double>([
    TweenSequenceItem(weight: 50, tween: Tween(begin: 0.0, end: -0.12)),
    TweenSequenceItem(weight: 50, tween: Tween(begin: -0.12, end: 0.0)),
  ]).animate(CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeOut)));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.rotate(
          angle: _wiggle.value,
          child: Transform.scale(scale: _bounce.value, child: child),
        ),
        child: SizedBox(
          width: widget.baseSize,
          height: widget.baseSize,
          child: Center(
            child: Text(
              widget.glyph,
              style: TextStyle(
                fontSize: widget.baseSize * 0.62,
                shadows: const [Shadow(color: Colors.black45, blurRadius: 8)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kAccentColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.chewy(fontSize: 12, color: Colors.black54),
            ),
            Text(
              value,
              style: GoogleFonts.chewy(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
