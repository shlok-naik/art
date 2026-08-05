/// Real, per-user stats an [Achievement]'s unlock condition can check —
/// gathered from the same repositories that already back the Stats/Profile
/// screens, not achievement-specific queries.
class AchievementStats {
  const AchievementStats({
    required this.sessionCount,
    required this.currentStreakDays,
    required this.totalMinutes,
    required this.longestMinutes,
    required this.finishedProjectCount,
    required this.averageDifficulty,
    required this.postCount,
    required this.totalViews,
    required this.followerCount,
    required this.reactionsReceived,
    required this.workStyle,
  });

  final int sessionCount;
  final int currentStreakDays;
  final double totalMinutes;
  final double longestMinutes;
  final int finishedProjectCount;
  final double? averageDifficulty;
  final int postCount;
  final int totalViews;
  final int followerCount;
  final int reactionsReceived;
  final String? workStyle;

  static const empty = AchievementStats(
    sessionCount: 0,
    currentStreakDays: 0,
    totalMinutes: 0,
    longestMinutes: 0,
    finishedProjectCount: 0,
    averageDifficulty: null,
    postCount: 0,
    totalViews: 0,
    followerCount: 0,
    reactionsReceived: 0,
    workStyle: null,
  );
}

/// One entry in the achievement catalog. The catalog itself (this list of
/// definitions) is static content, same as any app's achievement list — what
/// makes achievements "real" is that *unlocked* state is computed from real
/// stats and persisted per-user in `user_achievements`, not the existence of
/// the definitions themselves.
class Achievement {
  const Achievement({
    required this.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });

  /// Stable id stored in `user_achievements.achievement_key` — never rename
  /// an existing key, only add new ones, or past unlocks orphan.
  final String key;
  final String emoji;
  final String title;
  final String description;
  final bool Function(AchievementStats stats) isUnlocked;
}

final achievementCatalog = <Achievement>[
  // Sessions
  Achievement(
    key: 'first_steps',
    emoji: '🎬',
    title: 'First Steps',
    description: 'Log your first session',
    isUnlocked: (s) => s.sessionCount >= 1,
  ),
  Achievement(
    key: 'getting_started',
    emoji: '🧭',
    title: 'Getting Started',
    description: 'Log 10 sessions',
    isUnlocked: (s) => s.sessionCount >= 10,
  ),
  Achievement(
    key: 'dedicated',
    emoji: '📅',
    title: 'Dedicated',
    description: 'Log 50 sessions',
    isUnlocked: (s) => s.sessionCount >= 50,
  ),
  Achievement(
    key: 'centurion',
    emoji: '💯',
    title: 'Centurion',
    description: 'Log 100 sessions',
    isUnlocked: (s) => s.sessionCount >= 100,
  ),

  // Streaks
  Achievement(
    key: 'streak_3',
    emoji: '🔥',
    title: 'On a Roll',
    description: 'Reach a 3-day streak',
    isUnlocked: (s) => s.currentStreakDays >= 3,
  ),
  Achievement(
    key: 'streak_7',
    emoji: '⚡',
    title: 'Week Warrior',
    description: 'Reach a 7-day streak',
    isUnlocked: (s) => s.currentStreakDays >= 7,
  ),
  Achievement(
    key: 'streak_30',
    emoji: '🌟',
    title: 'Unstoppable',
    description: 'Reach a 30-day streak',
    isUnlocked: (s) => s.currentStreakDays >= 30,
  ),

  // Time
  Achievement(
    key: 'hour_club',
    emoji: '⏱️',
    title: 'Hour Club',
    description: 'Log 10 hours of total session time',
    isUnlocked: (s) => s.totalMinutes >= 600,
  ),
  Achievement(
    key: 'deep_focus',
    emoji: '⏳',
    title: 'Deep Focus',
    description: 'Log 50 hours of total session time',
    isUnlocked: (s) => s.totalMinutes >= 3000,
  ),
  Achievement(
    key: 'marathoner',
    emoji: '🏃',
    title: 'Marathoner',
    description: 'Log 100 hours of total session time',
    isUnlocked: (s) => s.totalMinutes >= 6000,
  ),
  Achievement(
    key: 'long_haul',
    emoji: '🕰️',
    title: 'Long Haul',
    description: 'Complete a single session of 2+ hours',
    isUnlocked: (s) => s.longestMinutes >= 120,
  ),

  // Projects
  Achievement(
    key: 'finisher',
    emoji: '🏁',
    title: 'Finisher',
    description: 'Finish your first project',
    isUnlocked: (s) => s.finishedProjectCount >= 1,
  ),
  Achievement(
    key: 'prolific',
    emoji: '🎨',
    title: 'Prolific',
    description: 'Finish 5 projects',
    isUnlocked: (s) => s.finishedProjectCount >= 5,
  ),
  Achievement(
    key: 'completionist',
    emoji: '🏆',
    title: 'Completionist',
    description: 'Finish 10 projects',
    isUnlocked: (s) => s.finishedProjectCount >= 10,
  ),

  // Posting
  Achievement(
    key: 'debut',
    emoji: '📸',
    title: 'Debut',
    description: 'Share your first post',
    isUnlocked: (s) => s.postCount >= 1,
  ),
  Achievement(
    key: 'gallery',
    emoji: '🖼️',
    title: 'Gallery',
    description: 'Share 10 posts',
    isUnlocked: (s) => s.postCount >= 10,
  ),
  Achievement(
    key: 'influencer',
    emoji: '📢',
    title: 'Influencer',
    description: 'Share 50 posts',
    isUnlocked: (s) => s.postCount >= 50,
  ),

  // Followers
  Achievement(
    key: 'first_fan',
    emoji: '🌱',
    title: 'First Fan',
    description: 'Get your first follower',
    isUnlocked: (s) => s.followerCount >= 1,
  ),
  Achievement(
    key: 'rising_star',
    emoji: '⭐',
    title: 'Rising Star',
    description: 'Reach 10 followers',
    isUnlocked: (s) => s.followerCount >= 10,
  ),
  Achievement(
    key: 'crowd_favorite',
    emoji: '🎉',
    title: 'Crowd Favorite',
    description: 'Reach 50 followers',
    isUnlocked: (s) => s.followerCount >= 50,
  ),

  // Engagement
  Achievement(
    key: 'viral',
    emoji: '👀',
    title: 'Getting Noticed',
    description: 'Reach 100 total views across your posts',
    isUnlocked: (s) => s.totalViews >= 100,
  ),
  Achievement(
    key: 'sensation',
    emoji: '🚀',
    title: 'Sensation',
    description: 'Reach 1,000 total views across your posts',
    isUnlocked: (s) => s.totalViews >= 1000,
  ),
  Achievement(
    key: 'crowd_pleaser',
    emoji: '💖',
    title: 'Crowd Pleaser',
    description: 'Receive 50 reactions across your posts',
    isUnlocked: (s) => s.reactionsReceived >= 50,
  ),

  // Personality / difficulty
  Achievement(
    key: 'challenge_seeker',
    emoji: '😤',
    title: 'Challenge Seeker',
    description: 'Average difficulty of 8+ across your sessions',
    isUnlocked: (s) => (s.averageDifficulty ?? 0) >= 8,
  ),
  Achievement(
    key: 'night_owl',
    emoji: '🦉',
    title: 'Night Owl',
    description: 'Log most of your sessions late at night',
    isUnlocked: (s) => s.workStyle == 'Night Owl 🦉',
  ),
  Achievement(
    key: 'early_bird',
    emoji: '🐦',
    title: 'Early Bird',
    description: 'Log most of your sessions early in the morning',
    isUnlocked: (s) => s.workStyle == 'Early Bird 🐦',
  ),
];
