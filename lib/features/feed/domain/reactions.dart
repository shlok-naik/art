enum EmojiReaction { heart, laugh, wow, sad, angry }

bool isVoteReactionType(String reactionType) => reactionType == 'up' || reactionType == 'down';

/// Combined reaction state for one session: the public per-type counts plus
/// the current user's own reaction rows (needed for update/delete by id).
class SessionReactions {
  const SessionReactions({required this.counts, required this.mine});

  static const empty = SessionReactions(counts: {}, mine: []);

  final Map<String, int> counts;
  final List<Map<String, dynamic>> mine;

  /// The user's up/down vote row, if any.
  Map<String, dynamic>? get myVote => _firstMine(isVoteReactionType);

  /// The user's emoji reaction row, if any.
  Map<String, dynamic>? get myEmoji => _firstMine((type) => !isVoteReactionType(type));

  int get total => counts.values.fold(0, (a, b) => a + b);

  Map<String, dynamic>? _firstMine(bool Function(String reactionType) matches) {
    for (final reaction in mine) {
      final type = reaction['reaction_type']?.toString();
      if (type != null && matches(type)) return reaction;
    }
    return null;
  }
}

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
