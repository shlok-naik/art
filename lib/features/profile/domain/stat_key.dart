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
  leagueRank('leagueRank', 'League rank', Icons.emoji_events_outlined);

  const StatKey(this.storageKey, this.label, this.icon);

  final String storageKey;
  final String label;
  final IconData icon;

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
