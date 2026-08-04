import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/providers.dart';
import 'data/comments_repository.dart';
import 'data/feed_repository.dart';
import 'data/reactions_repository.dart';
import 'domain/comment.dart';
import 'domain/feed_post.dart';
import 'domain/reactions.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(supabaseClientProvider));
});

final reactionsRepositoryProvider = Provider<ReactionsRepository>((ref) {
  return ReactionsRepository(ref.watch(supabaseClientProvider));
});

final commentsRepositoryProvider = Provider<CommentsRepository>((ref) {
  return CommentsRepository(ref.watch(supabaseClientProvider));
});

/// Comments on a session, oldest first. Mutations (add/delete) just
/// invalidate this rather than applying optimistic state — comments aren't
/// as tap-latency-sensitive as reactions, so a plain refetch keeps this
/// simple.
final sessionCommentsProvider =
    FutureProvider.autoDispose.family<List<Comment>, String>((ref, sessionId) {
  return ref.watch(commentsRepositoryProvider).fetchComments(sessionId);
});

/// Every posted session across all users, newest first.
final feedPostsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) {
  return ref.watch(feedRepositoryProvider).fetchAllPosts();
});

/// Only the signed-in user's own posts — drives Home's "Most Recent Post"
/// card and the My Posts screen.
final myPostsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) {
  return ref.watch(feedRepositoryProvider).fetchMyPosts();
});

/// Reaction counts + the user's own reactions for one session, with fully
/// optimistic mutations: [SessionReactionsNotifier.react] updates state
/// synchronously (add, switch, or remove), fires the write in the
/// background, and reverts only if the write fails. No refetch is needed for
/// the user to see their own tap.
final sessionReactionsProvider = AsyncNotifierProvider.autoDispose
    .family<SessionReactionsNotifier, SessionReactions, String>(SessionReactionsNotifier.new);

class SessionReactionsNotifier extends AsyncNotifier<SessionReactions> {
  SessionReactionsNotifier(this._sessionId);

  final String _sessionId;

  @override
  Future<SessionReactions> build() async {
    final repo = ref.watch(reactionsRepositoryProvider);
    final results =
        await Future.wait([repo.fetchCounts(_sessionId), repo.fetchMyReactions(_sessionId)]);
    return SessionReactions(
      counts: results[0] as Map<String, int>,
      mine: results[1] as List<Map<String, dynamic>>,
    );
  }

  static bool _isPlaceholderId(dynamic id) => id.toString().startsWith('_optimistic_');

  /// Applies a tap on [reactionType] instantly: a new reaction is added, a
  /// tap on the currently-selected one removes it, and a tap on a different
  /// type in the same group (vote vs emoji) switches to it. The network
  /// write runs after the state change; on failure the change is reverted
  /// and the error rethrown for the caller to surface.
  Future<void> react(String reactionType) async {
    final current = state.value;
    if (current == null) return; // Initial load hasn't finished yet.

    final existing = isVoteReactionType(reactionType) ? current.myVote : current.myEmoji;
    // A previous tap's insert is still in flight (we only have a placeholder
    // id, so we can't update/delete the row yet). Ignore this tap rather
    // than desync from the server.
    if (existing != null && _isPlaceholderId(existing['id'])) return;

    final isRemoving = existing != null && existing['reaction_type'] == reactionType;
    final isSwitching = existing != null && !isRemoving;

    final counts = Map<String, int>.of(current.counts);
    final mine = List<Map<String, dynamic>>.of(current.mine);
    String? placeholderId;

    if (isRemoving) {
      counts[reactionType] = (counts[reactionType] ?? 1) - 1;
      mine.removeWhere((r) => r['id'] == existing['id']);
    } else if (isSwitching) {
      final oldType = existing['reaction_type'].toString();
      counts[oldType] = (counts[oldType] ?? 1) - 1;
      counts[reactionType] = (counts[reactionType] ?? 0) + 1;
      mine
        ..removeWhere((r) => r['id'] == existing['id'])
        ..add({...existing, 'reaction_type': reactionType});
    } else {
      placeholderId = '_optimistic_${DateTime.now().microsecondsSinceEpoch}';
      counts[reactionType] = (counts[reactionType] ?? 0) + 1;
      mine.add({'id': placeholderId, 'session_id': _sessionId, 'reaction_type': reactionType});
    }

    state = AsyncData(SessionReactions(counts: counts, mine: mine));

    final repo = ref.read(reactionsRepositoryProvider);
    try {
      if (isRemoving) {
        await repo.deleteReaction(existing['id'].toString());
      } else if (isSwitching) {
        await repo.updateReaction(
          reactionId: existing['id'].toString(),
          reactionType: reactionType,
        );
      } else {
        final row = await repo.createReaction(
          sessionId: _sessionId,
          reactionType: reactionType,
        );
        // Swap the placeholder for the real row so the next tap can
        // update/delete it by its server id.
        final latest = state.value;
        if (latest != null) {
          state = AsyncData(SessionReactions(
            counts: latest.counts,
            mine: [
              for (final r in latest.mine)
                if (r['id'] == placeholderId) row else r,
            ],
          ));
        }
      }
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
