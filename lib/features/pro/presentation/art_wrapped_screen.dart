import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
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
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: kAccentColor,
        appBar: AppBar(
          backgroundColor: kAccentColor,
          elevation: 0,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Your Art Wrapped',
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
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
                      style: GoogleFonts.chewy(fontSize: 16, color: Colors.white),
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
                      style: GoogleFonts.chewy(fontSize: 18, color: Colors.white70),
                    ),
                    Text(
                      _formatMinutes(stats.totalMinutes),
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 56, color: Colors.white),
                    ),
                    Text(
                      'across ${stats.sessionCount} session${stats.sessionCount == 1 ? '' : 's'}',
                      style: GoogleFonts.chewy(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _WrappedStatCard(
                            emoji: '🎨',
                            label: 'Projects',
                            value: '${stats.projectCount}',
                            sublabel: '${stats.finishedProjectCount} finished',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _WrappedStatCard(
                            emoji: '🔥',
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
                            emoji: '💪',
                            label: 'Hardest stage',
                            value: stats.hardestStage ?? '—',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _WrappedStatCard(
                            emoji: '🖌️',
                            label: 'Go-to tool',
                            value: stats.topTool ?? '—',
                          ),
                        ),
                      ],
                    ),
                    if (stats.personalityBadge != null) ...[
                      const SizedBox(height: 12),
                      _WrappedStatCard(
                        emoji: '⏰',
                        label: 'You are a',
                        value: stats.personalityBadge!,
                        fullWidth: true,
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      'Screenshot this to share your year in art.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chewy(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (error, _) => Center(
              child: Text(
                'Failed to load your recap: $error',
                textAlign: TextAlign.center,
                style: GoogleFonts.chewy(fontSize: 16, color: Colors.white),
              ),
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
    required this.emoji,
    required this.label,
    required this.value,
    this.sublabel,
    this.fullWidth = false,
  });

  final String emoji;
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
        border: Border.all(color: kBorderColor, width: kBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.chewy(fontSize: 12, color: Colors.black54)),
          Text(
            value,
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
          if (sublabel != null)
            Text(sublabel!, style: GoogleFonts.chewy(fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }
}
