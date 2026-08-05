import 'package:flutter/material.dart';

/// Every stat a user can choose to show on their public Stats page. The
/// [storageKey] is what's persisted in `profiles.visible_stats` — keep it
/// stable even if [label] changes.
enum StatKey {
  posts('posts', 'Posts', Icons.grid_on),
  followers('followers', 'Followers', Icons.people_outline),
  following('following', 'Following', Icons.person_add_alt_outlined),
  totalViews('totalViews', 'Total views', Icons.visibility_outlined),
  timeSpent('timeSpent', 'Time spent drawing', Icons.schedule_outlined),
  sessionCount('sessionCount', 'Sessions logged', Icons.brush_outlined),
  streak('streak', 'Current streak', Icons.local_fire_department_outlined),
  leagueRank('leagueRank', 'League rank', Icons.emoji_events_outlined),
  averageDifficulty('averageDifficulty', 'Average difficulty', Icons.speed_outlined),
  finishedProjects('finishedProjects', 'Finished projects', Icons.check_circle_outline),
  longestSession('longestSession', 'Longest session', Icons.timer_outlined),
  averageSessionLength('averageSessionLength', 'Avg. session length', Icons.hourglass_bottom_outlined),
  workStyle('workStyle', 'Work style', Icons.psychology_outlined),
  stageBreakdown('stageBreakdown', 'Time per stage (chart)', Icons.bar_chart, isChart: true),
  difficultySpread('difficultySpread', 'Difficulty spread (chart)', Icons.equalizer, isChart: true),
  projectStatus('projectStatus', 'Project status (chart)', Icons.pie_chart_outline, isChart: true);

  const StatKey(this.storageKey, this.label, this.icon, {this.isChart = false});

  final String storageKey;
  final String label;
  final IconData icon;

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
