import 'package:supabase_flutter/supabase_flutter.dart';

/// Session-derived aggregates for one user's Stats page — kept separate
/// from `analytics/providers.dart`, which is wired to the signed-in user's
/// own projects only, so a public profile can show another user's numbers.
/// Mirrors the free-tier metrics on the Analytics tab (total/average/longest
/// session, streak, work-style badge, average difficulty) — Pro-only
/// insights (top tools, activity heatmap, hourly patterns) are deliberately
/// left out of the public Stats page.
class SessionStats {
  const SessionStats({
    required this.totalMinutes,
    required this.averageMinutes,
    required this.longestMinutes,
    required this.sessionCount,
    required this.currentStreakDays,
    required this.averageDifficulty,
    required this.workStyle,
  });

  final double totalMinutes;
  final double averageMinutes;
  final double longestMinutes;
  final int sessionCount;
  final int currentStreakDays;
  final double? averageDifficulty;
  final String? workStyle;

  static const empty = SessionStats(
    totalMinutes: 0,
    averageMinutes: 0,
    longestMinutes: 0,
    sessionCount: 0,
    currentStreakDays: 0,
    averageDifficulty: null,
    workStyle: null,
  );
}

/// Project-level aggregates for a user's Stats page.
class ProjectStats {
  const ProjectStats({required this.totalCount, required this.finishedCount});

  final int totalCount;
  final int finishedCount;

  static const empty = ProjectStats(totalCount: 0, finishedCount: 0);
}

/// The canonical session stages, in the order the "Time per stage" chart
/// draws them — matches [kSessionStages] in the projects feature, kept as a
/// local constant so this data layer doesn't need to import a presentation
/// file from another feature.
const kStageOrder = ['Sketching', 'Outlining', 'Coloring', 'Rendering', 'Finishing Touches'];

/// Total minutes logged in one session stage, for the "Time per stage" bar
/// chart on a user's Stats page.
class StageMinutes {
  const StageMinutes({required this.stage, required this.totalMinutes});

  final String stage;
  final double totalMinutes;
}

class StatsRepository {
  StatsRepository(this._client);

  final SupabaseClient _client;

  Future<SessionStats> fetchSessionStats(String userId) async {
    final rows = await _client
        .from('sessions')
        .select('duration, difficulty, created_at, projects!inner(user_id)')
        .eq('projects.user_id', userId);
    final sessions = List<Map<String, dynamic>>.from(rows);
    if (sessions.isEmpty) return SessionStats.empty;

    final durations = [
      for (final s in sessions)
        if (double.tryParse(s['duration']?.toString() ?? '') case final seconds?) seconds / 60,
    ];
    final totalMinutes = durations.fold<double>(0, (sum, m) => sum + m);
    final longestMinutes = durations.isEmpty ? 0.0 : durations.reduce((a, b) => a > b ? a : b);

    final difficulties = [
      for (final s in sessions) ?double.tryParse(s['difficulty']?.toString() ?? ''),
    ];
    final averageDifficulty =
        difficulties.isEmpty ? null : difficulties.fold<double>(0, (sum, d) => sum + d) / difficulties.length;

    final days = <DateTime>{};
    final hourCounts = List<int>.filled(24, 0);
    for (final session in sessions) {
      final createdAt = DateTime.tryParse(session['created_at']?.toString() ?? '')?.toLocal();
      if (createdAt == null) continue;
      days.add(DateTime(createdAt.year, createdAt.month, createdAt.day));
      hourCounts[createdAt.hour]++;
    }

    return SessionStats(
      totalMinutes: totalMinutes,
      averageMinutes: durations.isEmpty ? 0 : totalMinutes / durations.length,
      longestMinutes: longestMinutes,
      sessionCount: sessions.length,
      currentStreakDays: _currentStreakDays(days),
      averageDifficulty: averageDifficulty,
      workStyle: _workStyle(hourCounts),
    );
  }

  /// Total minutes per session stage, in [kStageOrder]. Stages with no
  /// logged time still get a zero-minute entry so the chart always has a
  /// full, stable set of bars.
  Future<List<StageMinutes>> fetchStageMinutes(String userId) async {
    final rows = await _client
        .from('sessions')
        .select('stage, duration, projects!inner(user_id)')
        .eq('projects.user_id', userId);
    final sessions = List<Map<String, dynamic>>.from(rows);

    final totals = <String, double>{};
    for (final session in sessions) {
      final stage = session['stage']?.toString();
      if (stage == null || stage.isEmpty) continue;
      final seconds = double.tryParse(session['duration']?.toString() ?? '') ?? 0;
      totals[stage] = (totals[stage] ?? 0) + seconds / 60;
    }

    return [for (final stage in kStageOrder) StageMinutes(stage: stage, totalMinutes: totals[stage] ?? 0)];
  }

  Future<ProjectStats> fetchProjectStats(String userId) async {
    final rows = await _client.from('projects').select('completion_percent').eq('user_id', userId);
    final projects = List<Map<String, dynamic>>.from(rows);
    final finished = projects.where((p) => (int.tryParse(p['completion_percent']?.toString() ?? '') ?? 0) >= 100);
    return ProjectStats(totalCount: projects.length, finishedCount: finished.length);
  }

  /// Session count per difficulty rating, index 0 = difficulty 1, index 9 =
  /// difficulty 10 — same shape as `DifficultyAnalytics.histogram` in
  /// analytics/providers.dart, for the "Difficulty spread" chart.
  Future<List<int>> fetchDifficultyHistogram(String userId) async {
    final rows = await _client
        .from('sessions')
        .select('difficulty, projects!inner(user_id)')
        .eq('projects.user_id', userId);
    final sessions = List<Map<String, dynamic>>.from(rows);

    final histogram = List<int>.filled(10, 0);
    for (final session in sessions) {
      final difficulty = int.tryParse(session['difficulty']?.toString() ?? '');
      if (difficulty == null) continue;
      histogram[difficulty.clamp(1, 10) - 1]++;
    }
    return histogram;
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

  /// Same peak-hour heuristic as the Analytics tab's personality badge.
  String? _workStyle(List<int> hourCounts) {
    if (hourCounts.every((count) => count == 0)) return null;
    var peakHour = 0;
    for (var h = 1; h < 24; h++) {
      if (hourCounts[h] > hourCounts[peakHour]) peakHour = h;
    }
    if (peakHour >= 5 && peakHour < 11) return 'Early Bird 🐦';
    if (peakHour >= 11 && peakHour < 17) return 'Daytime Dabbler ☀️';
    if (peakHour >= 17 && peakHour < 22) return 'Evening Artist 🎨';
    return 'Night Owl 🦉';
  }
}
