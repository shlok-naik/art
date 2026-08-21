import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../pro/presentation/pro_screen.dart';
import '../../pro/providers.dart';
import '../../shell/main_shell.dart';
import 'difficulty_analytics_screen.dart';
import 'projects_analytics_screen.dart';
import 'stage_radar_screen.dart';
import 'time_analytics_screen.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: kInkColor),
      child: Scaffold(
        appBar: appThemedAppBar(context, 'Analytics'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                _AnalyticsBox(
                  label: 'Difficulty',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DifficultyAnalyticsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AnalyticsBox(
                  label: 'Projects',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProjectsAnalyticsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AnalyticsBox(
                  label: 'Time Spent',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TimeAnalyticsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AnalyticsBox(
                  label: isPro ? 'Pro Analytics' : 'Go Pro',
                  icon: isPro ? Icons.auto_awesome : Icons.lock,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => isPro ? const StageRadarScreen() : const ProScreen(),
                    ),
                  ),
                ),
              ],
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

class _AnalyticsBox extends StatelessWidget {
  const _AnalyticsBox({required this.label, this.icon, this.onTap});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: appCardDecoration(),
        alignment: Alignment.center,
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: kAccentColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.chewy(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: kAccentColor,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: GoogleFonts.chewy(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }
}
