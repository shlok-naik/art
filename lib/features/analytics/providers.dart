import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../projects/presentation/session_details_form.dart' show kSessionStages;
import '../projects/providers.dart';

class ProjectDifficulty {
  const ProjectDifficulty({
    required this.project,
    required this.title,
    required this.average,
    required this.sessionCount,
    required this.history,
  });

  final Map<String, dynamic> project;
  final String title;
  final double average;
  final int sessionCount;

  /// Difficulty of each session for this project, oldest first — used to
  /// draw a trend sparkline.
  final List<double> history;
}

class StageDifficulty {
  const StageDifficulty({required this.stage, required this.average});

  final String stage;
  final double? average;
}

class DifficultyAnalytics {
  const DifficultyAnalytics({
    required this.perProject,
    required this.perStage,
    required this.histogram,
  });

  final List<ProjectDifficulty> perProject;
  final List<StageDifficulty> perStage;

  /// Session count per difficulty rating, index 0 = difficulty 1, index 9 =
  /// difficulty 10.
  final List<int> histogram;
}

class _StageAccumulator {
  double total = 0;
  int count = 0;
}

/// A single session's data, flattened across whichever project it belongs
/// to, for analytics that need to look across all projects at once.
class SessionRecord {
  const SessionRecord({
    required this.project,
    required this.projectTitle,
    required this.difficulty,
    required this.durationSeconds,
    required this.stage,
    required this.toolsUsed,
    required this.createdAt,
  });

  final Map<String, dynamic> project;
  final String projectTitle;
  final double? difficulty;
  final double? durationSeconds;
  final String? stage;
  final List<String> toolsUsed;
  final DateTime? createdAt;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Timestamps from Supabase come back UTC. Analytics that bucket by hour or
/// calendar day (streaks, "when you work", monthly grouping) need local
/// time, or every bucket is off by the user's UTC offset.
DateTime? _parseLocalDateTime(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '')?.toLocal();
}

/// Every session across every project, flattened into one list. Fetched
/// once here (a single batched query, not one request per project) so the
/// analytics providers below don't each re-fetch the same data.
final allSessionsProvider = FutureProvider.autoDispose<List<SessionRecord>>((ref) async {
  final projects = await ref.watch(projectsListProvider.future);
  final sessionsRepo = ref.watch(sessionsRepositoryProvider);

  final projectsById = {for (final project in projects) project['id'].toString(): project};
  final sessions = await sessionsRepo.fetchSessionsForProjects(projectsById.keys.toList());

  final records = <SessionRecord>[];
  for (final session in sessions) {
    final project = projectsById[session['project_id'].toString()];
    if (project == null) continue;

    records.add(SessionRecord(
      project: project,
      projectTitle: project['title']?.toString() ?? project['id'].toString(),
      difficulty: _asDouble(session['difficulty']),
      durationSeconds: _asDouble(session['duration']),
      stage: session['stage']?.toString(),
      toolsUsed: (session['tools_used'] as List?)?.map((t) => t.toString()).toList() ?? const [],
      createdAt: _parseLocalDateTime(session['created_at']),
    ));
  }
  return records;
});

final difficultyAnalyticsProvider = FutureProvider.autoDispose<DifficultyAnalytics>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);

  final byProject = <String, List<SessionRecord>>{};
  for (final session in sessions) {
    final id = session.project['id'].toString();
    byProject.putIfAbsent(id, () => []).add(session);
  }

  final perProject = <ProjectDifficulty>[];
  final stageTotals = <String, _StageAccumulator>{};

  for (final entry in byProject.entries) {
    final projectSessions = entry.value;
    final withDifficulty = projectSessions.where((s) => s.difficulty != null).toList()
      ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));

    for (final session in withDifficulty) {
      if (session.stage == null || session.stage!.isEmpty) continue;
      final acc = stageTotals.putIfAbsent(session.stage!, () => _StageAccumulator());
      acc.total += session.difficulty!;
      acc.count++;
    }

    if (withDifficulty.isNotEmpty) {
      final difficulties = [for (final s in withDifficulty) s.difficulty!];
      final average = difficulties.reduce((a, b) => a + b) / difficulties.length;
      perProject.add(ProjectDifficulty(
        project: projectSessions.first.project,
        title: projectSessions.first.projectTitle,
        average: average,
        sessionCount: difficulties.length,
        history: difficulties,
      ));
    }
  }

  perProject.sort((a, b) => b.average.compareTo(a.average));

  final perStage = [
    for (final stage in kSessionStages)
      StageDifficulty(
        stage: stage,
        average: stageTotals.containsKey(stage)
            ? stageTotals[stage]!.total / stageTotals[stage]!.count
            : null,
      ),
  ]..sort((a, b) {
      if (a.average == null && b.average == null) return 0;
      if (a.average == null) return 1;
      if (b.average == null) return -1;
      return b.average!.compareTo(a.average!);
    });

  final histogram = List<int>.filled(10, 0);
  for (final session in sessions) {
    final difficulty = session.difficulty;
    if (difficulty == null) continue;
    final bucket = difficulty.round().clamp(1, 10) - 1;
    histogram[bucket]++;
  }

  return DifficultyAnalytics(perProject: perProject, perStage: perStage, histogram: histogram);
});

class RadarComparison {
  const RadarComparison({required this.recent, required this.older});

  /// Per-stage average difficulty for the more-recent half of your session
  /// history (chronological split, not a fixed date window — robust to
  /// sparse data).
  final List<StageDifficulty> recent;

  /// Per-stage average difficulty for the older half.
  final List<StageDifficulty> older;
}

class MonthlyDifficulty {
  const MonthlyDifficulty({required this.label, required this.average});

  final String label;
  final double average;
}

class DifficultyProInsights {
  const DifficultyProInsights({
    required this.radarComparison,
    required this.monthly,
    required this.growthPercent,
  });

  final RadarComparison? radarComparison;

  /// Average difficulty per calendar month, oldest first.
  final List<MonthlyDifficulty> monthly;

  /// Percent change between your first and most recent month's average
  /// difficulty — null if there isn't enough spread to say anything.
  final double? growthPercent;
}

const _monthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

List<StageDifficulty> _perStageDifficulty(List<SessionRecord> sessions) {
  final totals = <String, _StageAccumulator>{};
  for (final session in sessions) {
    if (session.difficulty == null || session.stage == null || session.stage!.isEmpty) continue;
    final acc = totals.putIfAbsent(session.stage!, () => _StageAccumulator());
    acc.total += session.difficulty!;
    acc.count++;
  }
  return [
    for (final stage in kSessionStages)
      StageDifficulty(
        stage: stage,
        average: totals.containsKey(stage) ? totals[stage]!.total / totals[stage]!.count : null,
      ),
  ];
}

/// Pro-only "deeper" difficulty insights: a recent-vs-older radar
/// comparison and a monthly growth curve. Held back from the free
/// Difficulty screen on purpose.
final difficultyProInsightsProvider = FutureProvider.autoDispose<DifficultyProInsights>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final withDifficulty = sessions.where((s) => s.difficulty != null && s.createdAt != null).toList()
    ..sort((a, b) => a.createdAt!.compareTo(b.createdAt!));

  RadarComparison? radarComparison;
  if (withDifficulty.length >= 4) {
    final mid = withDifficulty.length ~/ 2;
    radarComparison = RadarComparison(
      older: _perStageDifficulty(withDifficulty.sublist(0, mid)),
      recent: _perStageDifficulty(withDifficulty.sublist(mid)),
    );
  }

  final monthlyTotals = <String, _StageAccumulator>{};
  final monthlyOrder = <String>[];
  for (final session in withDifficulty) {
    final createdAt = session.createdAt!;
    final key = '${createdAt.year}-${createdAt.month}';
    if (!monthlyTotals.containsKey(key)) monthlyOrder.add(key);
    final acc = monthlyTotals.putIfAbsent(key, () => _StageAccumulator());
    acc.total += session.difficulty!;
    acc.count++;
  }

  final monthly = [
    for (final key in monthlyOrder)
      MonthlyDifficulty(
        label: _monthLabels[int.parse(key.split('-')[1]) - 1],
        average: monthlyTotals[key]!.total / monthlyTotals[key]!.count,
      ),
  ];

  double? growthPercent;
  if (monthly.length >= 2 && monthly.first.average != 0) {
    growthPercent = (monthly.last.average - monthly.first.average) / monthly.first.average * 100;
  }

  return DifficultyProInsights(
    radarComparison: radarComparison,
    monthly: monthly,
    growthPercent: growthPercent,
  );
});

class ProjectStats {
  const ProjectStats({
    required this.project,
    required this.title,
    required this.totalMinutes,
    required this.sessionCount,
    required this.createdAt,
    required this.lastActiveAt,
    required this.finishedStatus,
    required this.completionPercent,
  });

  final Map<String, dynamic> project;
  final String title;
  final double totalMinutes;
  final int sessionCount;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final String finishedStatus;
  final int completionPercent;
}

class StatusCount {
  const StatusCount({required this.status, required this.count});

  final String status;
  final int count;
}

class FastestFinish {
  const FastestFinish({required this.title, required this.days});

  final String title;
  final int days;
}

class ProjectsOverview {
  const ProjectsOverview({
    required this.perProject,
    required this.statusBreakdown,
    required this.fastestFinish,
  });

  /// Every project, sorted by total time invested (most first) — projects
  /// with no sessions yet sort to the bottom at 0.
  final List<ProjectStats> perProject;

  final List<StatusCount> statusBreakdown;

  /// Your quickest-completed project (100% completion), by days between
  /// creation and its most recent session — a proxy for finish date since
  /// there's no dedicated "finished at" timestamp.
  final FastestFinish? fastestFinish;
}

/// Free-tier "how are my projects doing" overview: time invested, session
/// count, and completion per project, plus a status breakdown. Deliberately
/// doesn't include the tool-usage/activity-heatmap data reserved for Pro.
final projectsOverviewProvider = FutureProvider.autoDispose<ProjectsOverview>((ref) async {
  final projects = await ref.watch(projectsListProvider.future);
  final sessions = await ref.watch(allSessionsProvider.future);

  final byProject = <String, List<SessionRecord>>{};
  for (final session in sessions) {
    final id = session.project['id'].toString();
    byProject.putIfAbsent(id, () => []).add(session);
  }

  final perProject = <ProjectStats>[];
  final statusTotals = <String, int>{};

  for (final project in projects) {
    final id = project['id'].toString();
    final title = project['title']?.toString() ?? id;
    final projectSessions = byProject[id] ?? const [];

    final totalSeconds = projectSessions.fold<double>(
      0,
      (sum, s) => sum + (s.durationSeconds ?? 0),
    );
    final timestamps = [for (final s in projectSessions) s.createdAt].whereType<DateTime>().toList()
      ..sort();

    final status = project['finished_status']?.toString();
    final normalizedStatus = (status == null || status.isEmpty) ? 'Unknown' : status;
    statusTotals[normalizedStatus] = (statusTotals[normalizedStatus] ?? 0) + 1;

    perProject.add(ProjectStats(
      project: project,
      title: title,
      totalMinutes: totalSeconds / 60,
      sessionCount: projectSessions.length,
      createdAt: _parseLocalDateTime(project['created_at']),
      lastActiveAt: timestamps.isEmpty ? null : timestamps.last,
      finishedStatus: normalizedStatus,
      completionPercent: int.tryParse(project['completion_percent']?.toString() ?? '') ?? 0,
    ));
  }

  perProject.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

  final statusBreakdown = [
    for (final entry in statusTotals.entries) StatusCount(status: entry.key, count: entry.value),
  ]..sort((a, b) => b.count.compareTo(a.count));

  FastestFinish? fastestFinish;
  for (final stats in perProject) {
    if (stats.completionPercent != 100) continue;
    if (stats.createdAt == null || stats.lastActiveAt == null) continue;
    final days = stats.lastActiveAt!.difference(stats.createdAt!).inDays;
    if (fastestFinish == null || days < fastestFinish.days) {
      fastestFinish = FastestFinish(title: stats.title, days: days);
    }
  }

  return ProjectsOverview(
    perProject: perProject,
    statusBreakdown: statusBreakdown,
    fastestFinish: fastestFinish,
  );
});

class StageTime {
  const StageTime({required this.stage, required this.totalMinutes, required this.averageMinutes});

  final String stage;
  final double? totalMinutes;
  final double? averageMinutes;
}

class LongestSession {
  const LongestSession({required this.projectTitle, required this.minutes});

  final String projectTitle;
  final double minutes;
}

class TimeAnalytics {
  const TimeAnalytics({
    required this.totalMinutes,
    required this.averageSessionMinutes,
    required this.longestSession,
    required this.perStage,
    required this.currentStreakDays,
    required this.personalityBadge,
  });

  final double totalMinutes;
  final double averageSessionMinutes;
  final LongestSession? longestSession;
  final List<StageTime> perStage;

  /// Consecutive days (ending today or yesterday) with at least one session.
  final int currentStreakDays;

  /// A short "Night Owl 🦉" / "Early Bird 🐦" style label derived from your
  /// most common session hour — a lightweight teaser of the Pro hourly chart.
  final String? personalityBadge;
}

String? _personalityBadge(List<SessionRecord> sessions) {
  final hours = [for (final s in sessions) s.createdAt?.hour].whereType<int>().toList();
  if (hours.isEmpty) return null;

  final counts = List<int>.filled(24, 0);
  for (final hour in hours) {
    counts[hour]++;
  }
  var peakHour = 0;
  for (var h = 1; h < 24; h++) {
    if (counts[h] > counts[peakHour]) peakHour = h;
  }

  if (peakHour >= 5 && peakHour < 11) return 'Early Bird 🐦';
  if (peakHour >= 11 && peakHour < 17) return 'Daytime Dabbler ☀️';
  if (peakHour >= 17 && peakHour < 22) return 'Evening Artist 🎨';
  return 'Night Owl 🦉';
}

int _currentStreakDays(List<SessionRecord> sessions) {
  final days = <DateTime>{};
  for (final session in sessions) {
    final createdAt = session.createdAt;
    if (createdAt == null) continue;
    days.add(DateTime(createdAt.year, createdAt.month, createdAt.day));
  }
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

/// Free-tier time-spent overview: total hours logged, average/longest
/// session, time invested per stage, current streak, and a "personality"
/// badge. Deliberately doesn't include the full time-of-day chart or
/// session-length trend reserved for Pro.
final timeAnalyticsProvider = FutureProvider.autoDispose<TimeAnalytics>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final timedSessions = sessions.where((s) => s.durationSeconds != null).toList();

  final totalMinutes = timedSessions.fold<double>(0, (sum, s) => sum + s.durationSeconds! / 60);
  final averageSessionMinutes = timedSessions.isEmpty ? 0.0 : totalMinutes / timedSessions.length;

  LongestSession? longestSession;
  for (final session in timedSessions) {
    final minutes = session.durationSeconds! / 60;
    if (longestSession == null || minutes > longestSession.minutes) {
      longestSession = LongestSession(projectTitle: session.projectTitle, minutes: minutes);
    }
  }

  final stageTotals = <String, double>{};
  final stageCounts = <String, int>{};
  for (final session in timedSessions) {
    if (session.stage == null || session.stage!.isEmpty) continue;
    stageTotals[session.stage!] = (stageTotals[session.stage!] ?? 0) + session.durationSeconds! / 60;
    stageCounts[session.stage!] = (stageCounts[session.stage!] ?? 0) + 1;
  }
  final perStage = [
    for (final stage in kSessionStages)
      StageTime(
        stage: stage,
        totalMinutes: stageTotals[stage],
        averageMinutes:
            stageTotals.containsKey(stage) ? stageTotals[stage]! / stageCounts[stage]! : null,
      ),
  ]..sort((a, b) {
      if (a.totalMinutes == null && b.totalMinutes == null) return 0;
      if (a.totalMinutes == null) return 1;
      if (b.totalMinutes == null) return -1;
      return b.totalMinutes!.compareTo(a.totalMinutes!);
    });

  return TimeAnalytics(
    totalMinutes: totalMinutes,
    averageSessionMinutes: averageSessionMinutes,
    longestSession: longestSession,
    perStage: perStage,
    currentStreakDays: _currentStreakDays(sessions),
    personalityBadge: _personalityBadge(sessions),
  );
});

class ToolUsage {
  const ToolUsage({required this.tool, required this.count});

  final String tool;
  final int count;
}

class ActivityDay {
  const ActivityDay({required this.date, required this.sessionCount});

  final DateTime date;
  final int sessionCount;
}

class NeedsAttentionProject {
  const NeedsAttentionProject({required this.title, required this.daysSinceActive});

  final String title;
  final int daysSinceActive;
}

class ProjectsProInsights {
  const ProjectsProInsights({
    required this.topTools,
    required this.activity,
    required this.hourlyActivity,
    required this.durationTrendMinutes,
    required this.needsAttention,
  });

  /// Most-used tools across every session, most-used first.
  final List<ToolUsage> topTools;

  /// One entry per day for the last 12 weeks (84 days), oldest first —
  /// used to draw a GitHub-style practice-consistency heatmap.
  final List<ActivityDay> activity;

  /// Session count by hour of day (index 0-23) — when you actually work.
  final List<int> hourlyActivity;

  /// Duration (minutes) of every session, chronological (oldest first).
  final List<double> durationTrendMinutes;

  /// Unfinished projects with no session in 30+ days, longest-idle first.
  final List<NeedsAttentionProject> needsAttention;
}

/// Pro-only "deeper" project insights: tool usage, a practice-activity
/// heatmap, a time-of-day pattern, session-length trend, and stale-project
/// nudges. Held back from the free overview.
final projectsProInsightsProvider = FutureProvider.autoDispose<ProjectsProInsights>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  final overview = await ref.watch(projectsOverviewProvider.future);

  final toolCounts = <String, int>{};
  for (final session in sessions) {
    for (final tool in session.toolsUsed) {
      if (tool.isEmpty) continue;
      toolCounts[tool] = (toolCounts[tool] ?? 0) + 1;
    }
  }
  final topTools = [
    for (final entry in toolCounts.entries) ToolUsage(tool: entry.key, count: entry.value),
  ]..sort((a, b) => b.count.compareTo(a.count));

  final today = DateTime.now();
  final startDay = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 83));
  final dayCounts = <DateTime, int>{};
  final hourlyActivity = List<int>.filled(24, 0);
  for (final session in sessions) {
    final createdAt = session.createdAt;
    if (createdAt == null) continue;
    hourlyActivity[createdAt.hour]++;

    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (day.isBefore(startDay)) continue;
    dayCounts[day] = (dayCounts[day] ?? 0) + 1;
  }

  final activity = [
    for (var i = 0; i < 84; i++)
      ActivityDay(
        date: startDay.add(Duration(days: i)),
        sessionCount: dayCounts[startDay.add(Duration(days: i))] ?? 0,
      ),
  ];

  final durationTrendMinutes = [
    for (final s in [...sessions]
      ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0))))
      if (s.durationSeconds != null) s.durationSeconds! / 60,
  ];

  final needsAttention = <NeedsAttentionProject>[];
  for (final stats in overview.perProject) {
    if (stats.completionPercent >= 100) continue;
    if (stats.lastActiveAt == null) continue;
    final daysSinceActive = today.difference(stats.lastActiveAt!).inDays;
    if (daysSinceActive < 30) continue;
    needsAttention.add(NeedsAttentionProject(title: stats.title, daysSinceActive: daysSinceActive));
  }
  needsAttention.sort((a, b) => b.daysSinceActive.compareTo(a.daysSinceActive));

  return ProjectsProInsights(
    topTools: topTools.take(6).toList(),
    activity: activity,
    hourlyActivity: hourlyActivity,
    durationTrendMinutes: durationTrendMinutes,
    needsAttention: needsAttention,
  );
});

class ArtWrappedStats {
  const ArtWrappedStats({
    required this.totalMinutes,
    required this.sessionCount,
    required this.projectCount,
    required this.finishedProjectCount,
    required this.hardestStage,
    required this.topTool,
    required this.currentStreakDays,
    required this.personalityBadge,
  });

  final double totalMinutes;
  final int sessionCount;
  final int projectCount;
  final int finishedProjectCount;
  final String? hardestStage;
  final String? topTool;
  final int currentStreakDays;
  final String? personalityBadge;
}

/// Pro-only "Art Wrapped" recap — a shareable summary combining data already
/// computed by the other analytics providers, all in one place.
final artWrappedProvider = FutureProvider.autoDispose<ArtWrappedStats>((ref) async {
  final time = await ref.watch(timeAnalyticsProvider.future);
  final difficulty = await ref.watch(difficultyAnalyticsProvider.future);
  final proInsights = await ref.watch(projectsProInsightsProvider.future);
  final overview = await ref.watch(projectsOverviewProvider.future);
  final sessions = await ref.watch(allSessionsProvider.future);

  StageDifficulty? hardest;
  for (final stage in difficulty.perStage) {
    if (stage.average == null) continue;
    if (hardest == null || stage.average! > hardest.average!) hardest = stage;
  }

  return ArtWrappedStats(
    totalMinutes: time.totalMinutes,
    sessionCount: sessions.length,
    projectCount: overview.perProject.length,
    finishedProjectCount: overview.perProject.where((p) => p.completionPercent >= 100).length,
    hardestStage: hardest?.stage,
    topTool: proInsights.topTools.isEmpty ? null : proInsights.topTools.first.tool,
    currentStreakDays: time.currentStreakDays,
    personalityBadge: time.personalityBadge,
  );
});
