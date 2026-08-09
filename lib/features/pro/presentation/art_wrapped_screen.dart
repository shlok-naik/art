import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../../analytics/providers.dart';
import '../../shell/main_shell.dart';

String _formatMinutes(double minutes) {
  if (minutes <= 0) return '0m';
  final totalMinutes = minutes.round();
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (hours == 0) return '${mins}m';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

/// Pro-only shareable recap — the destination behind the "Art Wrapped" card
/// on the Go Pro screen.
class ArtWrappedScreen extends ConsumerWidget {
  const ArtWrappedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(artWrappedProvider);

    return DefaultTextStyle(
      style: appBodyStyle(color: kInkColor),
      child: Scaffold(
        backgroundColor: kAccentColor,
        appBar: AppBar(
          backgroundColor: kAccentColor,
          surfaceTintColor: kAccentColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Your Art Wrapped',
            style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white),
          ),
        ),
        body: SafeArea(
          child: statsAsync.when(
            data: (stats) {
              if (stats.sessionCount == 0) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Log a few sessions to unlock your recap.',
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You put in',
                      style: appBodyStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
                    ),
                    Text(
                      _formatMinutes(stats.totalMinutes),
                      style: appHeadlineStyle(fontSize: 52, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'across ${stats.sessionCount} session${stats.sessionCount == 1 ? '' : 's'}',
                      style: appBodyStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _WrappedStatCard(
                            icon: AppIcons.folder,
                            label: 'Projects',
                            value: '${stats.projectCount}',
                            sublabel: '${stats.finishedProjectCount} finished',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _WrappedStatCard(
                            icon: AppIcons.flame,
                            label: 'Best streak',
                            value: '${stats.currentStreakDays}',
                            sublabel: stats.currentStreakDays == 1 ? 'day' : 'days',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _WrappedStatCard(
                            icon: AppIcons.barChart,
                            label: 'Hardest stage',
                            value: stats.hardestStage ?? '—',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _WrappedStatCard(
                            icon: AppIcons.pencil,
                            label: 'Go-to tool',
                            value: stats.topTool ?? '—',
                          ),
                        ),
                      ],
                    ),
                    if (stats.personalityBadge != null) ...[
                      const SizedBox(height: 12),
                      _WrappedStatCard(
                        icon: AppIcons.clock,
                        label: 'You are a',
                        value: stats.personalityBadge!,
                        fullWidth: true,
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      'Screenshot this to share your year in art.',
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (error, _) => AppErrorState(
              error: error,
              onDark: true,
              onRetry: () => ref.invalidate(artWrappedProvider),
            ),
          ),
        ),
        bottomNavigationBar: Consumer(
          builder: (context, ref, _) => AppBottomNav(
            currentIndex: -1,
            onTap: (i) => goToMainTab(context, ref, i),
          ),
        ),
      ),
    );
  }
}

class _WrappedStatCard extends StatelessWidget {
  const _WrappedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sublabel,
    this.fullWidth = false,
  });

  final String icon;
  final String label;
  final String value;
  final String? sublabel;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 18, color: kNavyColor),
          const SizedBox(height: 4),
          Text(label, style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kMutedColor)),
          Text(
            value,
            style: appBodyStyle(fontWeight: FontWeight.w600, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          if (sublabel != null)
            Text(sublabel!, style: appBodyStyle(fontSize: 12, color: kMutedColor)),
        ],
      ),
    );
  }
}
