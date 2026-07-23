import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

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
}
