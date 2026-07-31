import 'package:supabase_flutter/supabase_flutter.dart';

class FollowsRepository {
  FollowsRepository(this._client);

  final SupabaseClient _client;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<void> follow(String userId) async {
    final me = _currentUserId;
    if (me == null) throw Exception('Not signed in');
    await _client.from('follows').insert({'follower_id': me, 'followee_id': userId});
  }

  Future<void> unfollow(String userId) async {
    final me = _currentUserId;
    if (me == null) throw Exception('Not signed in');
    await _client.from('follows').delete().eq('follower_id', me).eq('followee_id', userId);
  }

  Future<bool> isFollowing(String userId) async {
    final me = _currentUserId;
    if (me == null) return false;
    final row = await _client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', me)
        .eq('followee_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<({int followers, int following})> fetchFollowCounts(String userId) async {
    final row = await _client
        .from('follow_counts')
        .select('followers_count, following_count')
        .eq('profile_id', userId)
        .maybeSingle();
    if (row == null) return (followers: 0, following: 0);
    return (
      followers: int.tryParse(row['followers_count'].toString()) ?? 0,
      following: int.tryParse(row['following_count'].toString()) ?? 0,
    );
  }

  /// Profiles the signed-in user follows, newest first.
  Future<List<Map<String, dynamic>>> fetchFollowing() async {
    final me = _currentUserId;
    if (me == null) return const [];
    final followRows = await _client
        .from('follows')
        .select('followee_id')
        .eq('follower_id', me)
        .order('created_at', ascending: false);
    final ids = [
      for (final row in List<Map<String, dynamic>>.from(followRows)) row['followee_id'].toString(),
    ];
    if (ids.isEmpty) return const [];
    final profiles = await _client
        .from('profiles')
        .select('id, username, display_name')
        .inFilter('id', ids);
    final byId = {
      for (final profile in List<Map<String, dynamic>>.from(profiles))
        profile['id'].toString(): profile,
    };
    // Preserve the newest-first order from the follows query.
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  /// Profiles the signed-in user doesn't already follow, for a "suggested
  /// artists" list. No ranking algorithm — just newest profiles first.
  Future<List<Map<String, dynamic>>> fetchSuggested({int limit = 5}) async {
    final me = _currentUserId;
    final following = me == null ? const <String>[] : await _fetchFollowingIds(me);
    final excluded = {...following, ?me};

    final rows = await _client
        .from('profiles')
        .select('id, username, display_name')
        .order('created_at', ascending: false)
        .limit(limit + excluded.length);
    return List<Map<String, dynamic>>.from(rows)
        .where((row) => !excluded.contains(row['id'].toString()))
        .take(limit)
        .toList();
  }

  Future<List<String>> _fetchFollowingIds(String userId) async {
    final rows = await _client.from('follows').select('followee_id').eq('follower_id', userId);
    return [for (final row in List<Map<String, dynamic>>.from(rows)) row['followee_id'].toString()];
  }
}
