import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../auth/providers.dart';
import '../feed/providers.dart';
import '../profile/providers.dart';
import 'data/achievements_repository.dart';
import 'domain/achievement.dart';

final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  return AchievementsRepository(ref.watch(supabaseClientProvider));
});

/// Keys already celebrated (had their confetti screen shown) this app
/// session — not autoDispose, so it survives for as long as the app is
/// running. [newlyUnlockedAchievementsProvider] can legitimately report the
/// same key more than once (e.g. Supabase's auth stream firing twice on
/// cold start re-triggers the whole check before the first run's DB insert
/// is reflected back), so the celebration UI filters against this rather
/// than trusting every emission to be genuinely new.
final celebratedAchievementKeysProvider = StateProvider<Set<String>>((ref) => {});

/// Achievement keys a given user has actually unlocked, mapped to when —
/// works for any profile, so a visitor's public profile can show real
/// locked/unlocked state too, not just the owner's.
final unlockedAchievementsProvider =
    FutureProvider.autoDispose.family<Map<String, DateTime>, String>((ref, userId) {
  return ref.watch(achievementsRepositoryProvider).fetchUnlocked(userId);
});

/// Gathers the real, already-computed stats each achievement's unlock
/// condition checks against, from the same repositories the Stats/Profile
/// screens use — no achievement-specific queries beyond
/// [receivedReactionsCountProvider], which had no existing equivalent.
final achievementStatsProvider =
    FutureProvider.autoDispose.family<AchievementStats, String>((ref, userId) async {
  final sessionStats = await ref.watch(sessionStatsProvider(userId).future);
  final projectStats = await ref.watch(projectStatsProvider(userId).future);
  final followCounts = await ref.watch(followCountsProvider(userId).future);
  final posts = await ref.watch(userPostsProvider(userId).future);
  final reactionsReceived = await ref.watch(receivedReactionsCountProvider(userId).future);
  final commentsPosted = await ref.watch(postedCommentsCountProvider(userId).future);

  final totalViews = posts.fold<int>(0, (sum, post) => sum + post.views);

  return AchievementStats(
    sessionCount: sessionStats.sessionCount,
    currentStreakDays: sessionStats.currentStreakDays,
    totalMinutes: sessionStats.totalMinutes,
    longestMinutes: sessionStats.longestMinutes,
    totalProjectCount: projectStats.totalCount,
    finishedProjectCount: projectStats.finishedCount,
    averageDifficulty: sessionStats.averageDifficulty,
    postCount: posts.length,
    totalViews: totalViews,
    followerCount: followCounts.followers,
    followingCount: followCounts.following,
    reactionsReceived: reactionsReceived,
    commentsPosted: commentsPosted,
    workStyle: sessionStats.workStyle,
  );
});

/// Achievements the signed-in user's current stats qualify for but that
/// aren't yet recorded in `user_achievements` — computing this value unlocks
/// them (persists a row per newly-met condition) as a side effect, then
/// returns just the ones that were newly unlocked, for the UI to celebrate.
///
/// Re-running this against unchanged stats returns an empty list: every
/// achievement it finds gets persisted immediately, so the next evaluation
/// already sees it in [unlockedAchievementsProvider] and skips it. Callers
/// should invalidate this provider after actions that can move the
/// underlying stats (finishing a session, posting, gaining a follower).
final newlyUnlockedAchievementsProvider = FutureProvider.autoDispose<List<Achievement>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) return const [];
  final userId = profile.id;

  final stats = await ref.watch(achievementStatsProvider(userId).future);
  final alreadyUnlocked = await ref.watch(unlockedAchievementsProvider(userId).future);

  final repo = ref.watch(achievementsRepositoryProvider);
  final newlyUnlocked = <Achievement>[];
  for (final achievement in achievementCatalog) {
    if (!alreadyUnlocked.containsKey(achievement.key) && achievement.isUnlocked(stats)) {
      await repo.unlock(userId, achievement.key);
      newlyUnlocked.add(achievement);
    }
  }
  if (newlyUnlocked.isNotEmpty) {
    ref.invalidate(unlockedAchievementsProvider(userId));
  }
  return newlyUnlocked;
});
