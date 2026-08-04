class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.visibleStats,
  });

  final String id;
  final String username;
  final String displayName;

  /// Stat keys (see [StatKey]) this user has chosen to show on their public
  /// Stats page — raw storage keys, not yet resolved against the enum.
  final List<String> visibleStats;

  factory Profile.fromMap(Map<String, dynamic> map) {
    final rawVisibleStats = map['visible_stats'];
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      displayName: map['display_name'] as String,
      visibleStats: rawVisibleStats is List
          ? rawVisibleStats.map((e) => e.toString()).toList()
          : const <String>[],
    );
  }
}
