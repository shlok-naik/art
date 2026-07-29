import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../domain/feed_post.dart';

enum _EmojiReaction { heart, laugh, wow, sad, angry }

const _emojiGlyphs = {
  _EmojiReaction.heart: '❤️',
  _EmojiReaction.laugh: '😆',
  _EmojiReaction.wow: '😮',
  _EmojiReaction.sad: '😢',
  _EmojiReaction.angry: '😠',
};

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
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: dummyFeedPosts.length,
        itemBuilder: (context, index) =>
            _FeedPostCard(post: dummyFeedPosts[index]),
      ),
    );
  }
}

class _FeedPostCard extends StatefulWidget {
  const _FeedPostCard({required this.post});

  final FeedPost post;

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  int _slideIndex = 0;
  bool? _thumbsUp;
  _EmojiReaction? _selectedEmoji;

  late int _upCount = 340 + widget.post.id.hashCode.remainder(200).abs();
  late int _downCount = 4 + widget.post.id.hashCode.remainder(6).abs();
  late final Map<_EmojiReaction, int> _emojiCounts = {
    for (final reaction in _EmojiReaction.values)
      reaction:
          8 +
          (widget.post.id.hashCode + reaction.index * 17).remainder(60).abs(),
  };

  void _toggleThumb(bool up) {
    setState(() {
      if (_thumbsUp == up) {
        // Tapping the active thumb again clears it.
        if (up) {
          _upCount--;
        } else {
          _downCount--;
        }
        _thumbsUp = null;
        return;
      }
      if (_thumbsUp == true) _upCount--;
      if (_thumbsUp == false) _downCount--;
      if (up) {
        _upCount++;
      } else {
        _downCount++;
      }
      _thumbsUp = up;
    });
  }

  void _toggleEmoji(_EmojiReaction reaction) {
    setState(() {
      if (_selectedEmoji == reaction) {
        _emojiCounts[reaction] = _emojiCounts[reaction]! - 1;
        _selectedEmoji = null;
        return;
      }
      if (_selectedEmoji != null) {
        _emojiCounts[_selectedEmoji!] = _emojiCounts[_selectedEmoji!]! - 1;
      }
      _emojiCounts[reaction] = _emojiCounts[reaction]! + 1;
      _selectedEmoji = reaction;
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
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: post.slideCount,
          onPageChanged: (index) => setState(() => _slideIndex = index),
          itemBuilder: (context, index) => Container(
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
                  left: 4,
                  right: 76,
                  bottom: 78,
                  child: _PostCaption(post: post),
                ),
                Positioned(
                  right: 4,
                  bottom: 78,
                  child: _RightActionColumn(
                    thumbsUp: _thumbsUp,
                    upCount: _upCount,
                    downCount: _downCount,
                    onThumbUp: () => _toggleThumb(true),
                    onThumbDown: () => _toggleThumb(false),
                    onMore: _showDetails,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _EmojiReactionRow(
                    counts: _emojiCounts,
                    selected: _selectedEmoji,
                    onSelect: _toggleEmoji,
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

  final Map<_EmojiReaction, int> counts;
  final _EmojiReaction? selected;
  final ValueChanged<_EmojiReaction> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final reaction in _EmojiReaction.values)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReactionCircle(
                glyph: _emojiGlyphs[reaction]!,
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
