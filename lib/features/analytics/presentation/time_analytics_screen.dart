import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../../shared/app_theme.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';

String _formatMinutes(double minutes) {
  if (minutes <= 0) return '0m';
  final totalMinutes = minutes.round();
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (hours == 0) return '${mins}m';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

class TimeAnalyticsScreen extends ConsumerWidget {
  const TimeAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeAsync = ref.watch(timeAnalyticsProvider);

    return DefaultTextStyle(
      style: appBodyStyle(color: kInkColor),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Time Spent'),
        body: SafeArea(
          child: timeAsync.when(
            data: (time) {
              if (time.totalMinutes <= 0) {
                return Center(
                  child: Text(
                    'No time logged yet — finish a session to see analytics here.',
                    textAlign: TextAlign.center,
                    style: appBodyStyle(fontSize: 16),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total time logged',
                      style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    _TotalTimeHero(minutes: time.totalMinutes),
                    const SizedBox(height: AppSpacing.space16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Avg session',
                            value: _formatMinutes(time.averageSessionMinutes),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: _StatTile(
                            label: time.longestSession == null
                                ? 'Longest session'
                                : 'Longest · ${time.longestSession!.projectTitle}',
                            value: time.longestSession == null
                                ? '—'
                                : _formatMinutes(time.longestSession!.minutes),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Current streak',
                            icon: time.currentStreakDays == 0 ? null : AppIcons.flame,
                            value: time.currentStreakDays == 0
                                ? '—'
                                : '${time.currentStreakDays} day${time.currentStreakDays == 1 ? '' : 's'}',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: _StatTile(
                            label: 'You are a',
                            value: time.personalityBadge ?? '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space20),
                    Text(
                      'Time per stage',
                      style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space16),
                      decoration: appFlatCardDecoration(),
                      child: Column(
                        children: [
                          for (final stage in time.perStage) ...[
                            _StageTimeRow(stage: stage, maxMinutes: time.perStage.first.totalMinutes),
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
              onRetry: () => ref.invalidate(timeAnalyticsProvider),
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

class _TotalTimeHero extends StatelessWidget {
  const _TotalTimeHero({required this.minutes});

  final double minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space20),
      decoration: BoxDecoration(
        color: kAccentColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const AppIcon(AppIcons.clock, size: 30, color: Colors.white),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMinutes(minutes),
                  style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 30, color: Colors.white),
                ),
                Text(
                  'across every project',
                  style: appBodyStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.icon});

  final String label;
  final String value;

  /// Optional leading [AppIcons] glyph, cobalt like the value it sits with.
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16, vertical: AppSpacing.space12),
      decoration: appFlatCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: appBodyStyle(fontSize: 12, color: kMutedColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              if (icon != null) ...[
                AppIcon(icon!, size: 14, color: kAccentColor),
                const SizedBox(width: AppSpacing.space4),
              ],
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 18, color: kAccentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageTimeRow extends StatelessWidget {
  const _StageTimeRow({required this.stage, required this.maxMinutes});

  final StageTime stage;
  final double? maxMinutes;

  @override
  Widget build(BuildContext context) {
    final minutes = stage.totalMinutes;
    final fraction = (minutes == null || maxMinutes == null || maxMinutes == 0)
        ? 0.0
        : (minutes / maxMinutes!).clamp(0.0, 1.0);
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
                    width: constraints.maxWidth * fraction,
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
          width: 52,
          child: Text(
            minutes == null ? 'N/A' : _formatMinutes(minutes),
            textAlign: TextAlign.right,
            style: appBodyStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: minutes == null ? kMutedColor : kAccentColor,
            ),
          ),
        ),
      ],
    );
  }
}
