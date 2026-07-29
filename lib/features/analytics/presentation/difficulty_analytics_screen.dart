import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/sparkline.dart';
import '../../projects/presentation/project_detail_screen.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';

class DifficultyAnalyticsScreen extends ConsumerWidget {
  const DifficultyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(difficultyAnalyticsProvider);

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Difficulty'),
        body: SafeArea(
          child: analyticsAsync.when(
            data: (analytics) {
              if (analytics.perProject.isEmpty) {
                return Center(
                  child: Text(
                    'No difficulty data yet — log a session to see analytics here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chewy(fontSize: 16),
                  ),
                );
              }
              final hardest = analytics.perProject.first;
              final rest = analytics.perProject.skip(1).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hardest project',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    _HardestProjectHero(
                      project: hardest,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(project: hardest.project),
                        ),
                      ),
                    ),
                    if (rest.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Other projects',
                        style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      for (final project in rest) ...[
                        _ProjectDifficultyRow(
                          project: project,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(project: project.project),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Average difficulty per stage',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: appCardDecoration(),
                      child: Column(
                        children: [
                          for (final stage in analytics.perStage) ...[
                            _StageBarRow(stage: stage),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: AppErrorText('Failed to load analytics: $error'),
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: -1,
          onTap: (i) => goToMainTab(context, ref, i),
        ),
      ),
    );
  }
}

class _HardestProjectHero extends StatelessWidget {
  const _HardestProjectHero({required this.project, required this.onTap});

  final ProjectDifficulty project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kAccentColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor, width: kBorderWidth),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.title,
                    style: GoogleFonts.chewy(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${project.sessionCount} session${project.sessionCount == 1 ? '' : 's'}',
                    style: GoogleFonts.chewy(fontSize: 14, color: Colors.white70),
                  ),
                  if (project.history.length > 1) ...[
                    const SizedBox(height: 10),
                    Sparkline(
                      values: project.history,
                      width: 140,
                      height: 32,
                      color: Colors.white,
                      minValue: 1,
                      maxValue: 10,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              project.average.toStringAsFixed(1),
              style: GoogleFonts.chewy(
                fontWeight: FontWeight.bold,
                fontSize: 40,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDifficultyRow extends StatelessWidget {
  const _ProjectDifficultyRow({required this.project, required this.onTap});

  final ProjectDifficulty project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: appCardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.title,
                    style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${project.sessionCount} session${project.sessionCount == 1 ? '' : 's'}',
                    style: GoogleFonts.chewy(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (project.history.length > 1)
              Sparkline(
                values: project.history,
                width: 60,
                height: 24,
                color: kAccentColor,
                minValue: 1,
                maxValue: 10,
              ),
            const SizedBox(width: 12),
            Text(
              '${project.average.toStringAsFixed(1)} / 10',
              style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18, color: kAccentColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageBarRow extends StatelessWidget {
  const _StageBarRow({required this.stage});

  final StageDifficulty stage;

  @override
  Widget build(BuildContext context) {
    final average = stage.average;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            stage.stage,
            style: GoogleFonts.chewy(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  Container(
                    height: 14,
                    width: average == null ? 0 : constraints.maxWidth * (average / 10).clamp(0, 1),
                    decoration: BoxDecoration(
                      color: kAccentColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text(
            average == null ? 'N/A' : average.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: GoogleFonts.chewy(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: average == null ? Colors.black38 : kAccentColor,
            ),
          ),
        ),
      ],
    );
  }
}

