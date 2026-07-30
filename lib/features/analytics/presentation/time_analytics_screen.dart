import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
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
      style: GoogleFonts.chewy(color: Colors.black),
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
                      'Total time logged',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    _TotalTimeHero(minutes: time.totalMinutes),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Avg session',
                            value: _formatMinutes(time.averageSessionMinutes),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                    const SizedBox(height: 20),
                    Text(
                      'Time per stage',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: appCardDecoration(),
                      child: Column(
                        children: [
                          for (final stage in time.perStage) ...[
                            _StageTimeRow(stage: stage, maxMinutes: time.perStage.first.totalMinutes),
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

class _TotalTimeHero extends StatelessWidget {
  const _TotalTimeHero({required this.minutes});

  final double minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kAccentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor, width: kBorderWidth),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMinutes(minutes),
                  style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 34, color: Colors.white),
                ),
                Text(
                  'across every project',
                  style: GoogleFonts.chewy(fontSize: 14, color: Colors.white70),
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
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: appCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.chewy(fontSize: 12, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20, color: kAccentColor),
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
          width: 52,
          child: Text(
            minutes == null ? 'N/A' : _formatMinutes(minutes),
            textAlign: TextAlign.right,
            style: GoogleFonts.chewy(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: minutes == null ? Colors.black38 : kAccentColor,
            ),
          ),
        ),
      ],
    );
  }
}
