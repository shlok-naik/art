import '../../../shared/app_icons.dart';

/// Every stat a user can choose to show on their public Stats page. The
/// [storageKey] is what's persisted in `profiles.visible_stats` — keep it
/// stable even if [label] changes.
enum StatKey {
  posts('posts', 'Posts', AppIcons.grid),
  followers('followers', 'Followers', AppIcons.followed),
  following('following', 'Following', AppIcons.personAdd),
  totalViews('totalViews', 'Total views', AppIcons.eye),
  timeSpent('timeSpent', 'Time spent drawing', AppIcons.clock),
  sessionCount('sessionCount', 'Sessions logged', AppIcons.brush),
  streak('streak', 'Current streak', AppIcons.flame),
  leagueRank('leagueRank', 'League rank', AppIcons.trophy),
  averageDifficulty('averageDifficulty', 'Average difficulty', AppIcons.gauge),
  finishedProjects('finishedProjects', 'Finished projects', AppIcons.checkCircle),
  longestSession('longestSession', 'Longest session', AppIcons.clock),
  averageSessionLength('averageSessionLength', 'Avg. session length', AppIcons.hourglass),
  workStyle('workStyle', 'Work style', AppIcons.brain),
  stageBreakdown('stageBreakdown', 'Time per stage (chart)', AppIcons.barChart, isChart: true),
  difficultySpread('difficultySpread', 'Difficulty spread (chart)', AppIcons.barChart, isChart: true),
  projectStatus('projectStatus', 'Project status (chart)', AppIcons.pieChart, isChart: true);

  const StatKey(this.storageKey, this.label, this.icon, {this.isChart = false});

  final String storageKey;
  final String label;

  /// An [AppIcons] entry rather than an [IconData] — the redesign renders
  /// every glyph from the shared outline set.
  final String icon;

  /// Whether this stat renders as a full-width chart card on the Stats page
  /// rather than a grid tile.
  final bool isChart;

  static StatKey? fromStorageKey(String raw) {
    for (final key in StatKey.values) {
      if (key.storageKey == raw) return key;
    }
    return null;
  }
}

List<StatKey> statKeysFromStorage(List<String> raw) {
  return [for (final r in raw) if (StatKey.fromStorageKey(r) != null) StatKey.fromStorageKey(r)!];
}
