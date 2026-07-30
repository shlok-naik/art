import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../shell/main_shell.dart';
import 'difficulty_analytics_screen.dart';
import 'projects_analytics_screen.dart';
import 'stage_radar_screen.dart';
import 'time_analytics_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
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
                const _AnalyticsBox(locked: true),
              ],
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

class _AnalyticsBox extends StatelessWidget {
  const _AnalyticsBox({this.label = 'Analytics', this.locked = false, this.onTap});

  final String label;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: locked
          ? () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StageRadarScreen()),
            )
          : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: appCardDecoration(),
        alignment: Alignment.center,
        child: locked
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: kAccentColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Go Pro',
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
