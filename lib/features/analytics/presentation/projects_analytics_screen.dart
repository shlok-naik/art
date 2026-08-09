import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../projects/presentation/project_detail_screen.dart';
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

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${_monthNames[date.month - 1]} ${date.day}';
}

class ProjectsAnalyticsScreen extends ConsumerWidget {
  const ProjectsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(projectsOverviewProvider);

    return DefaultTextStyle(
      style: appBodyStyle(color: kInkColor),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Projects'),
        body: SafeArea(
          child: overviewAsync.when(
            data: (overview) {
              if (overview.perProject.isEmpty) {
                return Center(
                  child: Text(
                    'No projects yet — start one to see analytics here.',
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
                      'Status',
                      style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: appFlatCardDecoration(),
                      child: Column(
                        children: [
                          for (final status in overview.statusBreakdown) ...[
                            _StatusRow(status: status, total: overview.perProject.length),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    if (overview.fastestFinish != null) ...[
                      const SizedBox(height: 12),
                      _FastestFinishCard(fastestFinish: overview.fastestFinish!),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Completion',
                      style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: appFlatCardDecoration(),
                      child: Column(
                        children: [
                          for (final project in [...overview.perProject]
                            ..sort((a, b) => b.completionPercent.compareTo(a.completionPercent))) ...[
                            _CompletionRow(stats: project),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Time invested per project',
                      style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    for (final project in overview.perProject) ...[
                      _ProjectStatsRow(
                        stats: project,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProjectDetailScreen(project: project.project),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppErrorState(
              error: error,
              onRetry: () => ref.invalidate(projectsOverviewProvider),
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status, required this.total});

  final StatusCount status;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : status.count / total;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            status.status,
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
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            '${status.count}',
            textAlign: TextAlign.right,
            style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kAccentColor),
          ),
        ),
      ],
    );
  }
}

class _FastestFinishCard extends StatelessWidget {
  const _FastestFinishCard({required this.fastestFinish});

  final FastestFinish fastestFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kAccentTintColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHairlineColor, width: 1),
      ),
      child: Row(
        children: [
          const AppIcon(AppIcons.clock, size: 20, color: kAccentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fastest finish',
                  style: appBodyStyle(fontSize: 12, color: kMutedColor),
                ),
                Text(
                  '${fastestFinish.title} · ${fastestFinish.days} day${fastestFinish.days == 1 ? '' : 's'}',
                  style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionRow extends StatelessWidget {
  const _CompletionRow({required this.stats});

  final ProjectStats stats;

  @override
  Widget build(BuildContext context) {
    final isFinished = stats.completionPercent >= 100;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            stats.title,
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
                    width: constraints.maxWidth * (stats.completionPercent / 100).clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: isFinished ? kSuccessTextColor : kAccentColor,
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
          width: 44,
          child: isFinished
              ? const Align(
                  alignment: Alignment.centerRight,
                  child: AppIcon(AppIcons.checkCircle, size: 16, color: kSuccessTextColor),
                )
              : Text(
                  '${stats.completionPercent}%',
                  textAlign: TextAlign.right,
                  style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 14, color: kAccentColor),
                ),
        ),
      ],
    );
  }
}

class _ProjectStatsRow extends StatelessWidget {
  const _ProjectStatsRow({required this.stats, required this.onTap});

  final ProjectStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: appFlatCardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stats.title,
                    style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stats.sessionCount == 0
                        ? 'No sessions yet'
                        : '${stats.sessionCount} session${stats.sessionCount == 1 ? '' : 's'} · '
                            'last active ${_formatDate(stats.lastActiveAt)}',
                    style: appBodyStyle(fontSize: 13, color: kMutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatMinutes(stats.totalMinutes),
              style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 18, color: kAccentColor),
            ),
          ],
        ),
      ),
    );
  }
}
