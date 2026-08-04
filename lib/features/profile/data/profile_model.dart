class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.visibleStats,
    this.bio,
    this.pinnedPostId,
  });

  final String id;
  final String username;
  final String displayName;
  final String? bio;

  /// The session id, if any, the user has pinned to the top of their public
  /// profile's post grid.
  final String? pinnedPostId;

  /// Stat keys (see [StatKey]) this user has chosen to show on their public
  /// Stats page — raw storage keys, not yet resolved against the enum.
  final List<String> visibleStats;

  factory Profile.fromMap(Map<String, dynamic> map) {
    final rawVisibleStats = map['visible_stats'];
    final rawBio = map['bio']?.toString();
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      displayName: map['display_name'] as String,
      bio: (rawBio == null || rawBio.isEmpty) ? null : rawBio,
      pinnedPostId: map['pinned_post_id']?.toString(),
      visibleStats: rawVisibleStats is List
          ? rawVisibleStats.map((e) => e.toString()).toList()
          : const <String>[],
    );
  }
}
