import 'package:art/features/feed/domain/reactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isVoteReactionType', () {
    test('recognises up and down votes only', () {
      expect(isVoteReactionType('up'), isTrue);
      expect(isVoteReactionType('down'), isTrue);
      expect(isVoteReactionType('heart'), isFalse);
    });
  });

  group('SessionReactions', () {
    const reactions = SessionReactions(
      counts: {'up': 3, 'down': 1, 'heart': 2},
      mine: [
        {'id': 'vote-1', 'reaction_type': 'up'},
        {'id': 'emoji-1', 'reaction_type': 'heart'},
      ],
    );

    test('calculates the total count', () {
      expect(reactions.total, 6);
    });

    test('finds the current user’s vote and emoji reactions', () {
      expect(reactions.myVote?['id'], 'vote-1');
      expect(reactions.myEmoji?['id'], 'emoji-1');
    });

    test('empty state has no user reactions or counts', () {
      expect(SessionReactions.empty.total, 0);
      expect(SessionReactions.empty.myVote, isNull);
      expect(SessionReactions.empty.myEmoji, isNull);
    });
  });

  group('ReactionCounts', () {
    test('builds typed counts and fills missing reaction types with zero', () {
      final counts = ReactionCounts.fromCountsMap({
        'up': 4,
        'down': 1,
        'heart': 2,
        'wow': 3,
      });

      expect(counts.upCount, 4);
      expect(counts.downCount, 1);
      expect(counts.emojiCounts[EmojiReaction.heart], 2);
      expect(counts.emojiCounts[EmojiReaction.wow], 3);
      expect(counts.emojiCounts[EmojiReaction.sad], 0);
      expect(counts.total, 10);
    });
  });
}
