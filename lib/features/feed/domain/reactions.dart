enum EmojiReaction { heart, laugh, wow, sad, angry }

const emojiGlyphs = {
  EmojiReaction.heart: '❤️',
  EmojiReaction.laugh: '😆',
  EmojiReaction.wow: '😮',
  EmojiReaction.sad: '😢',
  EmojiReaction.angry: '😠',
};

/// Reaction counts for a single session, broken down by type. Build one from
/// the raw {reaction_type: count} map returned by the reaction_counts view
/// via [ReactionCounts.fromCountsMap].
class ReactionCounts {
  const ReactionCounts({
    required this.upCount,
    required this.downCount,
    required this.emojiCounts,
  });

  factory ReactionCounts.fromCountsMap(Map<String, int> counts) {
    return ReactionCounts(
      upCount: counts['up'] ?? 0,
      downCount: counts['down'] ?? 0,
      emojiCounts: {
        for (final reaction in EmojiReaction.values) reaction: counts[reaction.name] ?? 0,
      },
    );
  }

  static const empty = ReactionCounts(
    upCount: 0,
    downCount: 0,
    emojiCounts: {
      EmojiReaction.heart: 0,
      EmojiReaction.laugh: 0,
      EmojiReaction.wow: 0,
      EmojiReaction.sad: 0,
      EmojiReaction.angry: 0,
    },
  );

  final int upCount;
  final int downCount;
  final Map<EmojiReaction, int> emojiCounts;

  int get total => upCount + downCount + emojiCounts.values.fold(0, (a, b) => a + b);
}
