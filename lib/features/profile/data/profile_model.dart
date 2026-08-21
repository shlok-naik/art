class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.visibleStats,
    this.bio,
    this.pinnedPostId,
    this.city,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final String? bio;

  /// Public URL of the user's profile picture, if they've uploaded one.
  final String? avatarUrl;

  /// The session id, if any, the user has pinned to the top of their public
  /// profile's post grid.
  final String? pinnedPostId;

  /// Free-text city this user competes in — null until they've picked one,
  /// which gates entry to the weekly league (see NoCitySelectedException).
  final String? city;

  /// Stat keys (see [StatKey]) this user has chosen to show on their public
  /// Stats page — raw storage keys, not yet resolved against the enum.
  final List<String> visibleStats;

  factory Profile.fromMap(Map<String, dynamic> map) {
    final rawVisibleStats = map['visible_stats'];
    final rawBio = map['bio']?.toString();
    final rawCity = map['city']?.toString();
    final rawAvatarUrl = map['avatar_url']?.toString();
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      displayName: map['display_name'] as String,
      bio: (rawBio == null || rawBio.isEmpty) ? null : rawBio,
      pinnedPostId: map['pinned_post_id']?.toString(),
      city: (rawCity == null || rawCity.isEmpty) ? null : rawCity,
      avatarUrl: (rawAvatarUrl == null || rawAvatarUrl.isEmpty) ? null : rawAvatarUrl,
      visibleStats: rawVisibleStats is List
          ? rawVisibleStats.map((e) => e.toString()).toList()
          : const <String>[],
    );
  }
}
