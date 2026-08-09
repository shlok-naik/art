import '../../../shared/app_icons.dart';

/// Real, per-user stats an [Achievement]'s unlock condition can check —
/// gathered from the same repositories that already back the Stats/Profile
/// screens, not achievement-specific queries.
class AchievementStats {
  const AchievementStats({
    required this.sessionCount,
    required this.currentStreakDays,
    required this.totalMinutes,
    required this.longestMinutes,
    required this.totalProjectCount,
    required this.finishedProjectCount,
    required this.averageDifficulty,
    required this.postCount,
    required this.totalViews,
    required this.followerCount,
    required this.followingCount,
    required this.reactionsReceived,
    required this.commentsPosted,
    required this.workStyle,
  });

  final int sessionCount;
  final int currentStreakDays;
  final double totalMinutes;
  final double longestMinutes;
  final int totalProjectCount;
  final int finishedProjectCount;
  final double? averageDifficulty;
  final int postCount;
  final int totalViews;
  final int followerCount;
  final int followingCount;
  final int reactionsReceived;
  final int commentsPosted;
  final String? workStyle;

  static const empty = AchievementStats(
    sessionCount: 0,
    currentStreakDays: 0,
    totalMinutes: 0,
    longestMinutes: 0,
    totalProjectCount: 0,
    finishedProjectCount: 0,
    averageDifficulty: null,
    postCount: 0,
    totalViews: 0,
    followerCount: 0,
    followingCount: 0,
    reactionsReceived: 0,
    commentsPosted: 0,
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
    required this.icon,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });

  /// Stable id stored in `user_achievements.achievement_key` — never rename
  /// an existing key, only add new ones, or past unlocks orphan.
  final String key;

  /// An [AppIcons] entry — the redesign renders every achievement as an
  /// outline line icon, not a color emoji.
  final String icon;

  final String title;
  final String description;
  final bool Function(AchievementStats stats) isUnlocked;
}

final achievementCatalog = <Achievement>[
  // Sessions
  Achievement(
    key: 'first_steps',
    icon: AppIcons.play,
    title: 'First Steps',
    description: 'Log your first session',
    isUnlocked: (s) => s.sessionCount >= 1,
  ),
  Achievement(
    key: 'getting_started',
    icon: AppIcons.globe,
    title: 'Getting Started',
    description: 'Log 10 sessions',
    isUnlocked: (s) => s.sessionCount >= 10,
  ),
  Achievement(
    key: 'dedicated',
    icon: AppIcons.clock,
    title: 'Dedicated',
    description: 'Log 50 sessions',
    isUnlocked: (s) => s.sessionCount >= 50,
  ),
  Achievement(
    key: 'centurion',
    icon: AppIcons.checkCircle,
    title: 'Centurion',
    description: 'Log 100 sessions',
    isUnlocked: (s) => s.sessionCount >= 100,
  ),

  // Streaks
  Achievement(
    key: 'streak_3',
    icon: AppIcons.flame,
    title: 'On a Roll',
    description: 'Reach a 3-day streak',
    isUnlocked: (s) => s.currentStreakDays >= 3,
  ),
  Achievement(
    key: 'streak_7',
    icon: AppIcons.flame,
    title: 'Week Warrior',
    description: 'Reach a 7-day streak',
    isUnlocked: (s) => s.currentStreakDays >= 7,
  ),
  Achievement(
    key: 'streak_30',
    icon: AppIcons.star,
    title: 'Unstoppable',
    description: 'Reach a 30-day streak',
    isUnlocked: (s) => s.currentStreakDays >= 30,
  ),

  // Time
  Achievement(
    key: 'hour_club',
    icon: AppIcons.clock,
    title: 'Hour Club',
    description: 'Log 10 hours of total session time',
    isUnlocked: (s) => s.totalMinutes >= 600,
  ),
  Achievement(
    key: 'deep_focus',
    icon: AppIcons.clock,
    title: 'Deep Focus',
    description: 'Log 50 hours of total session time',
    isUnlocked: (s) => s.totalMinutes >= 3000,
  ),
  Achievement(
    key: 'marathoner',
    icon: AppIcons.clock,
    title: 'Marathoner',
    description: 'Log 100 hours of total session time',
    isUnlocked: (s) => s.totalMinutes >= 6000,
  ),
  Achievement(
    key: 'long_haul',
    icon: AppIcons.clock,
    title: 'Long Haul',
    description: 'Complete a single session of 2+ hours',
    isUnlocked: (s) => s.longestMinutes >= 120,
  ),

  // Projects
  Achievement(
    key: 'finisher',
    icon: AppIcons.checkCircle,
    title: 'Finisher',
    description: 'Finish your first project',
    isUnlocked: (s) => s.finishedProjectCount >= 1,
  ),
  Achievement(
    key: 'prolific',
    icon: AppIcons.pencil,
    title: 'Prolific',
    description: 'Finish 5 projects',
    isUnlocked: (s) => s.finishedProjectCount >= 5,
  ),
  Achievement(
    key: 'completionist',
    icon: AppIcons.trophy,
    title: 'Completionist',
    description: 'Finish 10 projects',
    isUnlocked: (s) => s.finishedProjectCount >= 10,
  ),

  // Posting
  Achievement(
    key: 'debut',
    icon: AppIcons.image,
    title: 'Debut',
    description: 'Share your first post',
    isUnlocked: (s) => s.postCount >= 1,
  ),
  Achievement(
    key: 'gallery',
    icon: AppIcons.image,
    title: 'Gallery',
    description: 'Share 10 posts',
    isUnlocked: (s) => s.postCount >= 10,
  ),
  Achievement(
    key: 'influencer',
    icon: AppIcons.share,
    title: 'Influencer',
    description: 'Share 50 posts',
    isUnlocked: (s) => s.postCount >= 50,
  ),

  // Followers
  Achievement(
    key: 'first_fan',
    icon: AppIcons.heart,
    title: 'First Fan',
    description: 'Get your first follower',
    isUnlocked: (s) => s.followerCount >= 1,
  ),
  Achievement(
    key: 'rising_star',
    icon: AppIcons.star,
    title: 'Rising Star',
    description: 'Reach 10 followers',
    isUnlocked: (s) => s.followerCount >= 10,
  ),
  Achievement(
    key: 'crowd_favorite',
    icon: AppIcons.star,
    title: 'Crowd Favorite',
    description: 'Reach 50 followers',
    isUnlocked: (s) => s.followerCount >= 50,
  ),

  // Engagement
  Achievement(
    key: 'viral',
    icon: AppIcons.eye,
    title: 'Getting Noticed',
    description: 'Reach 100 total views across your posts',
    isUnlocked: (s) => s.totalViews >= 100,
  ),
  Achievement(
    key: 'sensation',
    icon: AppIcons.barChart,
    title: 'Sensation',
    description: 'Reach 1,000 total views across your posts',
    isUnlocked: (s) => s.totalViews >= 1000,
  ),
  Achievement(
    key: 'crowd_pleaser',
    icon: AppIcons.heartFilled,
    title: 'Crowd Pleaser',
    description: 'Receive 50 reactions across your posts',
    isUnlocked: (s) => s.reactionsReceived >= 50,
  ),

  // Personality / difficulty
  Achievement(
    key: 'challenge_seeker',
    icon: AppIcons.flame,
    title: 'Challenge Seeker',
    description: 'Average difficulty of 8+ across your sessions',
    isUnlocked: (s) => (s.averageDifficulty ?? 0) >= 8,
  ),
  Achievement(
    key: 'night_owl',
    icon: AppIcons.clock,
    title: 'Night Owl',
    description: 'Log most of your sessions late at night',
    isUnlocked: (s) => s.workStyle == 'Night Owl',
  ),
  Achievement(
    key: 'early_bird',
    icon: AppIcons.clock,
    title: 'Early Bird',
    description: 'Log most of your sessions early in the morning',
    isUnlocked: (s) => s.workStyle == 'Early Bird',
  ),
  Achievement(
    key: 'daytime_dabbler',
    icon: AppIcons.clock,
    title: 'Daytime Dabbler',
    description: 'Log most of your sessions during the day',
    isUnlocked: (s) => s.workStyle == 'Daytime Dabbler',
  ),
  Achievement(
    key: 'evening_artist',
    icon: AppIcons.clock,
    title: 'Evening Artist',
    description: 'Log most of your sessions in the evening',
    isUnlocked: (s) => s.workStyle == 'Evening Artist',
  ),
  Achievement(
    key: 'zen_artist',
    icon: AppIcons.clock,
    title: 'Zen Artist',
    description: 'Average difficulty of 3 or under across your sessions',
    isUnlocked: (s) => s.averageDifficulty != null && s.averageDifficulty! <= 3,
  ),

  // More session/streak/time tiers
  Achievement(
    key: 'quarter_century',
    icon: AppIcons.checkCircle,
    title: 'Quarter Century',
    description: 'Log 25 sessions',
    isUnlocked: (s) => s.sessionCount >= 25,
  ),
  Achievement(
    key: 'unrelenting',
    icon: AppIcons.trophy,
    title: 'Unrelenting',
    description: 'Log 200 sessions',
    isUnlocked: (s) => s.sessionCount >= 200,
  ),
  Achievement(
    key: 'streak_14',
    icon: AppIcons.flame,
    title: 'Two Weeks Strong',
    description: 'Reach a 14-day streak',
    isUnlocked: (s) => s.currentStreakDays >= 14,
  ),
  Achievement(
    key: 'warming_up',
    icon: AppIcons.barChart,
    title: 'Warming Up',
    description: 'Log 5 hours of total session time',
    isUnlocked: (s) => s.totalMinutes >= 300,
  ),
  Achievement(
    key: 'legend',
    icon: AppIcons.crown,
    title: 'Legend',
    description: 'Log 250 hours of total session time',
    isUnlocked: (s) => s.totalMinutes >= 15000,
  ),
  Achievement(
    key: 'iron_will',
    icon: AppIcons.flame,
    title: 'Iron Will',
    description: 'Complete a single session of 4+ hours',
    isUnlocked: (s) => s.longestMinutes >= 240,
  ),

  // Projects
  Achievement(
    key: 'new_canvas',
    icon: AppIcons.pencil,
    title: 'New Canvas',
    description: 'Start your first project',
    isUnlocked: (s) => s.totalProjectCount >= 1,
  ),
  Achievement(
    key: 'idea_factory',
    icon: AppIcons.plus,
    title: 'Idea Factory',
    description: 'Start 10 projects',
    isUnlocked: (s) => s.totalProjectCount >= 10,
  ),
  Achievement(
    key: 'overflowing_sketchbook',
    icon: AppIcons.folder,
    title: 'Overflowing Sketchbook',
    description: 'Start 25 projects',
    isUnlocked: (s) => s.totalProjectCount >= 25,
  ),
  Achievement(
    key: 'master_craftsman',
    icon: AppIcons.folder,
    title: 'Master Craftsman',
    description: 'Finish 20 projects',
    isUnlocked: (s) => s.finishedProjectCount >= 20,
  ),

  // Posting / views / reactions — fills below and above the existing tiers
  Achievement(
    key: 'media_mogul',
    icon: AppIcons.feed,
    title: 'Media Mogul',
    description: 'Share 100 posts',
    isUnlocked: (s) => s.postCount >= 100,
  ),
  Achievement(
    key: 'first_impressions',
    icon: AppIcons.followed,
    title: 'First Impressions',
    description: 'Reach 10 total views across your posts',
    isUnlocked: (s) => s.totalViews >= 10,
  ),
  Achievement(
    key: 'viral_sensation',
    icon: AppIcons.globe,
    title: 'Viral Sensation',
    description: 'Reach 10,000 total views across your posts',
    isUnlocked: (s) => s.totalViews >= 10000,
  ),
  Achievement(
    key: 'well_liked',
    icon: AppIcons.smile,
    title: 'Well Liked',
    description: 'Receive 10 reactions across your posts',
    isUnlocked: (s) => s.reactionsReceived >= 10,
  ),
  Achievement(
    key: 'beloved',
    icon: AppIcons.heartFilled,
    title: 'Beloved',
    description: 'Receive 200 reactions across your posts',
    isUnlocked: (s) => s.reactionsReceived >= 200,
  ),
  Achievement(
    key: 'local_celebrity',
    icon: AppIcons.grid,
    title: 'Local Celebrity',
    description: 'Reach 100 followers',
    isUnlocked: (s) => s.followerCount >= 100,
  ),

  // Following / community
  Achievement(
    key: 'community_builder',
    icon: AppIcons.followed,
    title: 'Community Builder',
    description: 'Follow 10 other artists',
    isUnlocked: (s) => s.followingCount >= 10,
  ),
  Achievement(
    key: 'networker',
    icon: AppIcons.globe,
    title: 'Networker',
    description: 'Follow 50 other artists',
    isUnlocked: (s) => s.followingCount >= 50,
  ),

  // Comments
  Achievement(
    key: 'conversationalist',
    icon: AppIcons.comment,
    title: 'Conversationalist',
    description: 'Post your first comment',
    isUnlocked: (s) => s.commentsPosted >= 1,
  ),
  Achievement(
    key: 'chatterbox',
    icon: AppIcons.comment,
    title: 'Chatterbox',
    description: 'Post 25 comments',
    isUnlocked: (s) => s.commentsPosted >= 25,
  ),
];
