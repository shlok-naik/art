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
  const DifficultyAnalytics({required this.perProject, required this.perStage});

  final List<ProjectDifficulty> perProject;
  final List<StageDifficulty> perStage;
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
      createdAt: DateTime.tryParse(session['created_at']?.toString() ?? ''),
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

  return DifficultyAnalytics(perProject: perProject, perStage: perStage);
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
  });

  final Map<String, dynamic> project;
  final String title;
  final double totalMinutes;
  final int sessionCount;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final String finishedStatus;
}

class StatusCount {
  const StatusCount({required this.status, required this.count});

  final String status;
  final int count;
}

class ProjectsOverview {
  const ProjectsOverview({required this.perProject, required this.statusBreakdown});

  /// Every project, sorted by total time invested (most first) — projects
  /// with no sessions yet sort to the bottom at 0.
  final List<ProjectStats> perProject;

  final List<StatusCount> statusBreakdown;
}

/// Free-tier "how are my projects doing" overview: time invested and
/// session count per project, plus a status breakdown. Deliberately doesn't
/// include the tool-usage/activity-heatmap data reserved for Pro.
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

    final normalizedStatus = project['finished_status'] == true ? 'Finished' : 'In Progress';
    statusTotals[normalizedStatus] = (statusTotals[normalizedStatus] ?? 0) + 1;

    perProject.add(ProjectStats(
      project: project,
      title: title,
      totalMinutes: totalSeconds / 60,
      sessionCount: projectSessions.length,
      createdAt: DateTime.tryParse(project['created_at']?.toString() ?? ''),
      lastActiveAt: timestamps.isEmpty ? null : timestamps.last,
      finishedStatus: normalizedStatus,
    ));
  }

  perProject.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));

  final statusBreakdown = [
    for (final entry in statusTotals.entries) StatusCount(status: entry.key, count: entry.value),
  ]..sort((a, b) => b.count.compareTo(a.count));

  return ProjectsOverview(perProject: perProject, statusBreakdown: statusBreakdown);
});

class StageTime {
  const StageTime({required this.stage, required this.totalMinutes});

  final String stage;
  final double? totalMinutes;
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
  });

  final double totalMinutes;
  final double averageSessionMinutes;
  final LongestSession? longestSession;
  final List<StageTime> perStage;
}

/// Free-tier time-spent overview: total hours logged, average/longest
/// session, and time invested per stage. Deliberately doesn't include the
/// time-of-day pattern reserved for Pro.
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
  for (final session in timedSessions) {
    if (session.stage == null || session.stage!.isEmpty) continue;
    stageTotals[session.stage!] = (stageTotals[session.stage!] ?? 0) + session.durationSeconds! / 60;
  }
  final perStage = [
    for (final stage in kSessionStages) StageTime(stage: stage, totalMinutes: stageTotals[stage]),
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

class ProjectsProInsights {
  const ProjectsProInsights({
    required this.topTools,
    required this.activity,
    required this.hourlyActivity,
  });

  /// Most-used tools across every session, most-used first.
  final List<ToolUsage> topTools;

  /// One entry per day for the last 12 weeks (84 days), oldest first —
  /// used to draw a GitHub-style practice-consistency heatmap.
  final List<ActivityDay> activity;

  /// Session count by hour of day (index 0-23) — when you actually work.
  final List<int> hourlyActivity;
}

/// Pro-only "deeper" project insights: tool usage, a practice-activity
/// heatmap, and a time-of-day pattern. Held back from the free overview.
final projectsProInsightsProvider = FutureProvider.autoDispose<ProjectsProInsights>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);

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

  return ProjectsProInsights(
    topTools: topTools.take(6).toList(),
    activity: activity,
    hourlyActivity: hourlyActivity,
  );
});
