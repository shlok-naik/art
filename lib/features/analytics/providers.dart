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
    required this.createdAt,
  });

  final Map<String, dynamic> project;
  final String projectTitle;
  final double? difficulty;
  final double? durationSeconds;
  final String? stage;
  final DateTime? createdAt;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Every session across every project, flattened into one list. Fetched
/// once here so `difficultyAnalyticsProvider` and `progressOverTimeProvider`
/// don't each re-fetch the same data.
final allSessionsProvider = FutureProvider.autoDispose<List<SessionRecord>>((ref) async {
  final projects = await ref.watch(projectsListProvider.future);
  final sessionsRepo = ref.watch(sessionsRepositoryProvider);

  final records = <SessionRecord>[];
  for (final project in projects) {
    final id = project['id'].toString();
    final title = project['title']?.toString() ?? id;
    final sessions = await sessionsRepo.fetchSessions(id);

    for (final session in sessions) {
      records.add(SessionRecord(
        project: project,
        projectTitle: title,
        difficulty: _asDouble(session['difficulty']),
        durationSeconds: _asDouble(session['duration']),
        stage: session['stage']?.toString(),
        createdAt: DateTime.tryParse(session['created_at']?.toString() ?? ''),
      ));
    }
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

class ProgressOverTime {
  const ProgressOverTime({required this.difficultyTrend, required this.durationTrendMinutes});

  /// Difficulty of every session across all projects, chronological
  /// (oldest first).
  final List<double> difficultyTrend;

  /// Duration (minutes) of every session across all projects with a valid
  /// duration, chronological (oldest first).
  final List<double> durationTrendMinutes;
}

final progressOverTimeProvider = FutureProvider.autoDispose<ProgressOverTime>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);

  final sorted = [...sessions]
    ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));

  final difficultyTrend = [
    for (final s in sorted)
      if (s.difficulty != null) s.difficulty!,
  ];
  final durationTrendMinutes = [
    for (final s in sorted)
      if (s.durationSeconds != null) s.durationSeconds! / 60,
  ];

  return ProgressOverTime(
    difficultyTrend: difficultyTrend,
    durationTrendMinutes: durationTrendMinutes,
  );
});
