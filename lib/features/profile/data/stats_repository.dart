import 'package:supabase_flutter/supabase_flutter.dart';

/// Session-derived aggregates for one user's Stats page — kept separate
/// from `analytics/providers.dart`, which is wired to the signed-in user's
/// own projects only, so a public profile can show another user's numbers.
class SessionStats {
  const SessionStats({
    required this.totalMinutes,
    required this.sessionCount,
    required this.currentStreakDays,
  });

  final double totalMinutes;
  final int sessionCount;
  final int currentStreakDays;

  static const empty = SessionStats(totalMinutes: 0, sessionCount: 0, currentStreakDays: 0);
}

class StatsRepository {
  StatsRepository(this._client);

  final SupabaseClient _client;

  Future<SessionStats> fetchSessionStats(String userId) async {
    final rows = await _client
        .from('sessions')
        .select('duration, created_at, projects!inner(user_id)')
        .eq('projects.user_id', userId);
    final sessions = List<Map<String, dynamic>>.from(rows);

    final totalSeconds = sessions.fold<double>(
      0,
      (sum, s) => sum + (double.tryParse(s['duration']?.toString() ?? '') ?? 0),
    );

    final days = <DateTime>{};
    for (final session in sessions) {
      final createdAt = DateTime.tryParse(session['created_at']?.toString() ?? '')?.toLocal();
      if (createdAt == null) continue;
      days.add(DateTime(createdAt.year, createdAt.month, createdAt.day));
    }

    return SessionStats(
      totalMinutes: totalSeconds / 60,
      sessionCount: sessions.length,
      currentStreakDays: _currentStreakDays(days),
    );
  }

  int _currentStreakDays(Set<DateTime> days) {
    if (days.isEmpty) return 0;
    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
