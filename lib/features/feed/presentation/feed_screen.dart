import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../shell/main_shell.dart';
import '../domain/feed_post.dart';
import '../domain/reactions.dart';
import '../providers.dart';

bool _isVoteType(String reactionType) => reactionType == 'up' || reactionType == 'down';

Map<String, dynamic>? _findReaction(
  List<Map<String, dynamic>> reactions,
  bool Function(String reactionType) matches,
) {
  for (final reaction in reactions) {
    final type = reaction['reaction_type']?.toString();
    if (type != null && matches(type)) return reaction;
  }
  return null;
}

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
/// (for slideshows) horizontal swipe through a project's session photos.
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
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: posts.length,
            itemBuilder: (context, index) => _FeedPostCard(post: posts[index]),
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
  bool _isReacting = false;

  // Local overrides shown instantly on tap, before the network round-trip
  // completes, so reacting never has to wait for a refetch to "feel" like it
  // worked. Cleared once fresh data confirming the change has landed (or
  // reset to the pre-tap values if the request fails).
  Map<String, int>? _optimisticCounts;
  List<Map<String, dynamic>>? _optimisticMyReactions;

  String get _sessionId => widget.post.id;

  Future<void> _react(String reactionType, Map<String, dynamic>? existing) async {
    if (_isReacting) return;

    final previousCounts = _optimisticCounts ?? ref.read(reactionCountsProvider(_sessionId)).value ?? const {};
    final previousMyReactions =
        _optimisticMyReactions ?? ref.read(myReactionsProvider(_sessionId)).value ?? const [];

    final isRemoving = existing != null && existing['reaction_type'] == reactionType;
    final isSwitching = existing != null && !isRemoving;

    final optimisticCounts = Map<String, int>.of(previousCounts);
    final optimisticMyReactions = List<Map<String, dynamic>>.of(previousMyReactions);

    if (isRemoving) {
      optimisticCounts[reactionType] = (optimisticCounts[reactionType] ?? 1) - 1;
      optimisticMyReactions.removeWhere((r) => r['id'] == existing['id']);
    } else if (isSwitching) {
      final oldType = existing['reaction_type']?.toString();
      if (oldType != null) {
        optimisticCounts[oldType] = (optimisticCounts[oldType] ?? 1) - 1;
      }
      optimisticCounts[reactionType] = (optimisticCounts[reactionType] ?? 0) + 1;
      optimisticMyReactions
        ..removeWhere((r) => r['id'] == existing['id'])
        ..add({...existing, 'reaction_type': reactionType});
    } else {
      optimisticCounts[reactionType] = (optimisticCounts[reactionType] ?? 0) + 1;
      optimisticMyReactions.add({
        'id': '_optimistic_$reactionType',
        'session_id': _sessionId,
        'reaction_type': reactionType,
      });
    }

    setState(() {
      _isReacting = true;
      _optimisticCounts = optimisticCounts;
      _optimisticMyReactions = optimisticMyReactions;
    });

    final repo = ref.read(reactionsRepositoryProvider);
    try {
      if (isRemoving) {
        await repo.deleteReaction(existing['id'].toString());
      } else if (isSwitching) {
        await repo.updateReaction(reactionId: existing['id'].toString(), reactionType: reactionType);
      } else {
        await repo.createReaction(sessionId: _sessionId, reactionType: reactionType);
      }
      ref.invalidate(reactionCountsProvider(_sessionId));
      ref.invalidate(myReactionsProvider(_sessionId));
      try {
        // Wait for the real data before dropping the optimistic override,
        // so the UI never flashes back to the stale pre-tap counts while
        // the refetch is still in flight.
        await ref.read(reactionCountsProvider(_sessionId).future);
        await ref.read(myReactionsProvider(_sessionId).future);
      } catch (_) {
        // If the refetch itself fails, just keep showing the optimistic
        // value rather than surface a second, confusing error.
      }
      if (!mounted) return;
      setState(() {
        _optimisticCounts = null;
        _optimisticMyReactions = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _optimisticCounts = null;
        _optimisticMyReactions = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to react: $e')),
      );
    } finally {
      if (mounted) setState(() => _isReacting = false);
    }
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
                  post.projectTitle,
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
    // Prefer the optimistic local override (set instantly on tap) over
    // whatever's currently in the provider, so reacting never waits on a
    // network round-trip to be reflected on screen.
    final counts = _optimisticCounts ??
        ref.watch(reactionCountsProvider(_sessionId)).value ??
        const <String, int>{};
    final myReactions = _optimisticMyReactions ??
        ref.watch(myReactionsProvider(_sessionId)).value ??
        const <Map<String, dynamic>>[];
    final myVote = _findReaction(myReactions, _isVoteType);
    final myEmoji = _findReaction(myReactions, (type) => !_isVoteType(type));

    final thumbsUp = switch (myVote?['reaction_type']) {
      'up' => true,
      'down' => false,
      _ => null,
    };
    EmojiReaction? selectedEmoji;
    for (final reaction in EmojiReaction.values) {
      if (reaction.name == myEmoji?['reaction_type']) {
        selectedEmoji = reaction;
        break;
      }
    }

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
            return Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 54, color: Colors.black38),
              ),
            );
          },
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
                    thumbsUp: thumbsUp,
                    upCount: counts['up'] ?? 0,
                    downCount: counts['down'] ?? 0,
                    onThumbUp: () => _react('up', myVote),
                    onThumbDown: () => _react('down', myVote),
                    onMore: _showDetails,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _EmojiReactionRow(
                    counts: {
                      for (final reaction in EmojiReaction.values) reaction: counts[reaction.name] ?? 0,
                    },
                    selected: selectedEmoji,
                    onSelect: (reaction) => _react(reaction.name, myEmoji),
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

class _PostCaption extends StatelessWidget {
  const _PostCaption({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: kAccentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              post.type == FeedPostType.slideshow ? 'SLIDESHOW' : 'SESSION',
              style: GoogleFonts.chewy(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@${post.artist}',
            style: GoogleFonts.chewy(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              shadows: _shadow,
            ),
          ),
          Text(
            post.projectTitle,
            style: GoogleFonts.chewy(fontSize: 16, shadows: _shadow),
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
    required this.thumbsUp,
    required this.upCount,
    required this.downCount,
    required this.onThumbUp,
    required this.onThumbDown,
    required this.onMore,
  });

  final bool? thumbsUp;
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
        _ReactionCircle(
          glyph: '👍',
          isActive: thumbsUp == true,
          onTap: onThumbUp,
        ),
        Text(
          _formatCount(upCount),
          style: GoogleFonts.chewy(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            shadows: _shadow,
          ),
        ),
        const SizedBox(height: 14),
        _ReactionCircle(
          glyph: '👎',
          isActive: thumbsUp == false,
          onTap: onThumbDown,
        ),
        Text(
          _formatCount(downCount),
          style: GoogleFonts.chewy(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            shadows: _shadow,
          ),
        ),
        const SizedBox(height: 14),
        _CircleIconButton(icon: Icons.more_vert, onTap: onMore),
      ],
    );
  }
}

class _EmojiReactionRow extends StatelessWidget {
  const _EmojiReactionRow({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  final Map<EmojiReaction, int> counts;
  final EmojiReaction? selected;
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
              _ReactionCircle(
                glyph: emojiGlyphs[reaction]!,
                isActive: selected == reaction,
                onTap: () => onSelect(reaction),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCount(counts[reaction]!),
                style: GoogleFonts.chewy(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  shadows: _shadow,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ReactionCircle extends StatelessWidget {
  const _ReactionCircle({
    required this.glyph,
    required this.isActive,
    required this.onTap,
  });

  final String glyph;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isActive ? 46 : 40,
        height: isActive ? 46 : 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: isActive ? kAccentColor : kBorderColor,
            width: kBorderWidth,
          ),
        ),
        alignment: Alignment.center,
        child: Text(glyph, style: TextStyle(fontSize: isActive ? 22 : 18)),
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
