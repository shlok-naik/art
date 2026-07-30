enum EmojiReaction { heart, laugh, wow, sad, angry }

const emojiGlyphs = {
  EmojiReaction.heart: '❤️',
  EmojiReaction.laugh: '😆',
  EmojiReaction.wow: '😮',
  EmojiReaction.sad: '😢',
  EmojiReaction.angry: '😠',
};

/// Reaction counts for a single post. There's no reactions table backing
/// this yet, so counts are derived deterministically from the post id —
/// the same post always shows the same numbers everywhere in the app.
class ReactionCounts {
  const ReactionCounts({
    required this.upCount,
    required this.downCount,
    required this.emojiCounts,
  });

  final int upCount;
  final int downCount;
  final Map<EmojiReaction, int> emojiCounts;

  int get total =>
      upCount + downCount + emojiCounts.values.fold(0, (sum, count) => sum + count);
}

ReactionCounts baseReactionCounts(String postId) {
  final upCount = 340 + postId.hashCode.remainder(200).abs();
  final downCount = 4 + postId.hashCode.remainder(6).abs();
  final emojiCounts = {
    for (final reaction in EmojiReaction.values)
      reaction: 8 + (postId.hashCode + reaction.index * 17).remainder(60).abs(),
  };
  return ReactionCounts(upCount: upCount, downCount: downCount, emojiCounts: emojiCounts);
}
