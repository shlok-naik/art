import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementsRepository {
  AchievementsRepository(this._client);

  final SupabaseClient _client;

  /// Achievement keys [userId] has unlocked, mapped to when — publicly
  /// readable, so a visitor's profile can show real unlocked/locked state
  /// too, not just the owner's.
  Future<Map<String, DateTime>> fetchUnlocked(String userId) async {
    final rows = await _client
        .from('user_achievements')
        .select('achievement_key, unlocked_at')
        .eq('user_id', userId);
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['achievement_key'].toString(): DateTime.parse(row['unlocked_at'].toString()),
    };
  }

  /// Records an unlock. Upserts with `ignoreDuplicates` so re-checking an
  /// already-unlocked achievement (e.g. a stale client re-evaluating) is a
  /// silent no-op rather than a duplicate-key error.
  Future<void> unlock(String userId, String achievementKey) async {
    await _client.from('user_achievements').upsert(
      {'user_id': userId, 'achievement_key': achievementKey},
      onConflict: 'user_id,achievement_key',
      ignoreDuplicates: true,
    );
  }
}
