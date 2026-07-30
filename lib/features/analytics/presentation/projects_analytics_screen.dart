import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../projects/presentation/project_detail_screen.dart';
import '../../shell/main_shell.dart';
import '../providers.dart';
import 'stage_radar_screen.dart';

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
      style: GoogleFonts.chewy(color: Colors.black),
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
                    style: GoogleFonts.chewy(fontSize: 16),
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
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: appCardDecoration(),
                      child: Column(
                        children: [
                          for (final status in overview.statusBreakdown) ...[
                            _StatusRow(status: status, total: overview.perProject.length),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Time invested per project',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
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
                    const SizedBox(height: 10),
                    _ProInsightsTeaser(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StageRadarScreen()),
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
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 14, color: kAccentColor),
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
        decoration: appCardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stats.title,
                    style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stats.sessionCount == 0
                        ? 'No sessions yet'
                        : '${stats.sessionCount} session${stats.sessionCount == 1 ? '' : 's'} · '
                            'last active ${_formatDate(stats.lastActiveAt)}',
                    style: GoogleFonts.chewy(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatMinutes(stats.totalMinutes),
              style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18, color: kAccentColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProInsightsTeaser extends StatelessWidget {
  const _ProInsightsTeaser({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: kBorderColor, width: kBorderWidth),
          borderRadius: BorderRadius.circular(12),
          color: kAccentColor.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, color: kAccentColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See your top tools & practice streak',
                    style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Unlock with Pro',
                    style: GoogleFonts.chewy(fontSize: 13, color: kAccentColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kAccentColor),
          ],
        ),
      ),
    );
  }
}
