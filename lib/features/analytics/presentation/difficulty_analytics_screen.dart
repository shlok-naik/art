import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/sparkline.dart';
import '../../projects/presentation/project_detail_screen.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';

class DifficultyAnalyticsScreen extends ConsumerWidget {
  const DifficultyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(difficultyAnalyticsProvider);
    final timeAsync = ref.watch(timeAnalyticsProvider);

    return DefaultTextStyle(
      style: appBodyStyle(color: kInkColor),
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
                    style: appBodyStyle(fontSize: 16),
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
                      style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    _HardestProjectHero(
                      project: hardest,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(project: hardest.project),
                        ),
                      ),
                    ),
                    if (rest.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space20),
                      Text(
                        'Other projects',
                        style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      for (final project in rest) ...[
                        _ProjectDifficultyRow(
                          project: project,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(project: project.project),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.space20),
                    Text(
                      'Difficulty distribution',
                      style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: appFlatCardDecoration(),
                      child: _DifficultyHistogram(histogram: analytics.histogram),
                    ),
                    const SizedBox(height: AppSpacing.space20),
                    timeAsync.maybeWhen(
                      data: (time) {
                        final callout = _difficultyVsSpeedCallout(analytics.perStage, time.perStage);
                        if (callout == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.space20),
                          child: _CalloutCard(text: callout),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                    Text(
                      'Average difficulty per stage',
                      style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
                      decoration: appFlatCardDecoration(),
                      child: Column(
                        children: [
                          for (final stage in analytics.perStage) ...[
                            _StageBarRow(stage: stage),
                            const SizedBox(height: AppSpacing.space12),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const AppSkeletonScreen(),
            error: (error, _) => AppErrorState(
              error: error,
              onRetry: () => ref.invalidate(difficultyAnalyticsProvider),
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
        padding: const EdgeInsets.all(AppSpacing.space20),
        decoration: BoxDecoration(
          color: kAccentColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kHairlineColor, width: 1),
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
                    style: appBodyStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${project.sessionCount} session${project.sessionCount == 1 ? '' : 's'}',
                    style: appBodyStyle(fontSize: 14, color: Colors.white70),
                  ),
                  if (project.history.length > 1) ...[
                    const SizedBox(height: AppSpacing.space12),
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
            const SizedBox(width: AppSpacing.space12),
            Text(
              project.average.toStringAsFixed(1),
              style: appBodyStyle(
                fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
        decoration: appFlatCardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    project.title,
                    style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${project.sessionCount} session${project.sessionCount == 1 ? '' : 's'}',
                    style: appBodyStyle(fontSize: 13, color: kMutedColor),
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
            const SizedBox(width: AppSpacing.space12),
            Text(
              '${project.average.toStringAsFixed(1)} / 10',
              style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 18, color: kAccentColor),
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
            style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                      color: kHairlineColor,
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
        const SizedBox(width: AppSpacing.space12),
        SizedBox(
          width: 46,
          child: Text(
            average == null ? 'N/A' : average.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: appBodyStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: average == null ? kMutedColor : kAccentColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// A short "your hardest stage is also your slowest" style insight,
/// combining difficulty and time-per-stage data that's already computed
/// elsewhere. Null if there isn't enough data to say anything meaningful.
String? _difficultyVsSpeedCallout(List<StageDifficulty> difficulty, List<StageTime> time) {
  StageDifficulty? hardest;
  for (final stage in difficulty) {
    if (stage.average == null) continue;
    if (hardest == null || stage.average! > hardest.average!) hardest = stage;
  }

  StageTime? slowest;
  for (final stage in time) {
    if (stage.averageMinutes == null) continue;
    if (slowest == null || stage.averageMinutes! > slowest.averageMinutes!) slowest = stage;
  }

  if (hardest == null || slowest == null) return null;

  if (hardest.stage == slowest.stage) {
    return '${hardest.stage} is both your hardest and slowest stage.';
  }
  return '${hardest.stage} is your hardest stage — ${slowest.stage} takes you the longest.';
}

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
      decoration: BoxDecoration(
        color: kAccentTintColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHairlineColor, width: 1),
      ),
      child: Row(
        children: [
          const AppIcon(AppIcons.bulb, size: 20, color: kAccentColor),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(text, style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _DifficultyHistogram extends StatelessWidget {
  const _DifficultyHistogram({required this.histogram});

  /// Session count per difficulty rating, index 0 = difficulty 1.
  final List<int> histogram;

  @override
  Widget build(BuildContext context) {
    final maxCount = histogram.fold<int>(0, (max, c) => c > max ? c : max);
    return SizedBox(
      height: 100,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < histogram.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: maxCount == 0 ? 0 : histogram[i] / maxCount,
                        child: Container(
                          decoration: BoxDecoration(
                            color: histogram[i] == 0 ? kHairlineColor : kAccentColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              for (var i = 1; i <= 10; i++)
                Expanded(
                  child: Text(
                    '$i',
                    textAlign: TextAlign.center,
                    style: appBodyStyle(fontSize: 11, color: kMutedColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
