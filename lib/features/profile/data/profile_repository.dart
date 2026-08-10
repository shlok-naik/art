import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_model.dart';

/// Thrown when an update touches a column that doesn't exist yet on this
/// database — i.e. the schema is out of date with the app. Callers can
/// catch this to show a friendlier message than the raw Postgres error,
/// and to know whether anything still saved.
class MissingColumnException implements Exception {
  const MissingColumnException(this.message);

  final String message;

  @override
  String toString() => message;
}

bool _isUndefinedColumn(Object error) => error is PostgrestException && error.code == '42703';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  static const _avatarBucket = 'avatars';

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  Future<void> createProfile({
    required String userId,
    required String username,
    required String displayName,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'username': username,
      'display_name': displayName,
    });
  }

  Future<void> updateProfile({
    required String userId,
    required String username,
    required String displayName,
    required String? bio,
  }) async {
    try {
      await _client.from('profiles').update({
        'username': username,
        'display_name': displayName,
        'bio': bio,
      }).eq('id', userId);
    } catch (e) {
      if (!_isUndefinedColumn(e)) rethrow;
      // The `bio` column isn't on this database yet — save what we can
      // (username/display name) rather than let an unrelated pending
      // migration block basic profile edits.
      await _client.from('profiles').update({
        'username': username,
        'display_name': displayName,
      }).eq('id', userId);
      throw const MissingColumnException(
        'Your name and username were saved, but bio support needs a pending database update.',
      );
    }
  }

  /// Uploads a profile picture to a path keyed by [userId] (so re-uploading
  /// overwrites rather than accumulating old pictures) and returns its public
  /// URL. Does not touch the `profiles` row — pair with [updateAvatarUrl].
  Future<String> uploadAvatar(Uint8List bytes, String userId) async {
    final path = '$userId/avatar.jpg';
    await _client.storage.from(_avatarBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
    // Bust the CDN/browser cache for the overwritten file, since the URL
    // itself doesn't change between uploads.
    final publicUrl = _client.storage.from(_avatarBucket).getPublicUrl(path);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updateAvatarUrl({
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      await _client.from('profiles').update({'avatar_url': avatarUrl}).eq('id', userId);
    } catch (e) {
      if (!_isUndefinedColumn(e)) rethrow;
      throw const MissingColumnException(
        'Your profile picture was uploaded, but saving it needs a pending database update.',
      );
    }
  }

  Future<void> updateVisibleStats({
    required String userId,
    required List<String> visibleStats,
  }) async {
    await _client.from('profiles').update({'visible_stats': visibleStats}).eq('id', userId);
  }

  /// Sets or clears (pass null) the post pinned to the top of a profile's
  /// post grid.
  Future<void> updatePinnedPost({
    required String userId,
    required String? postId,
  }) async {
    try {
      await _client.from('profiles').update({'pinned_post_id': postId}).eq('id', userId);
    } catch (e) {
      if (!_isUndefinedColumn(e)) rethrow;
      throw const MissingColumnException('Pinning needs a pending database update.');
    }
  }

  /// Sets which [leagueRegions] key (see league_region.dart) this user
  /// competes in — required before they can enter a weekly league.
  Future<void> updateRegion({
    required String userId,
    required String region,
  }) async {
    try {
      await _client.from('profiles').update({'region': region}).eq('id', userId);
    } catch (e) {
      if (!_isUndefinedColumn(e)) rethrow;
      throw const MissingColumnException('Regional leagues need a pending database update.');
    }
  }
}
