import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_icons.dart';
import '../../../shared/app_spacing.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppScreenHeader(title: 'Analytics'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              child: Column(
                children: [
                  _AnalyticsRow(
                    icon: AppIcons.barChart,
                    label: 'Difficulty',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DifficultyAnalyticsScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  _AnalyticsRow(
                    icon: AppIcons.folder,
                    label: 'Projects',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProjectsAnalyticsScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  _AnalyticsRow(
                    icon: AppIcons.clock,
                    label: 'Time spent',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TimeAnalyticsScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  // The paywalled row keeps its distinct tinted treatment to
                  // signal it's the Pro one.
                  _AnalyticsRow(
                    icon: AppIcons.lock,
                    label: isPro ? 'Pro analytics' : 'Go Pro for deeper insights',
                    isPro: true,
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
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: -1,
        onTap: (i) => goToMainTab(context, ref, i),
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({
    required this.icon,
    required this.label,
    this.isPro = false,
    this.onTap,
  });

  final String icon;
  final String label;
  final bool isPro;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isPro ? kAccentColor : kInkColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20, vertical: AppSpacing.space20),
        decoration: appFlatCardDecoration(color: isPro ? kAccentTintColor : kSurfaceColor),
        child: Row(
          children: [
            AppIcon(icon, size: 22, color: color),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: Text(
                label,
                style: appBodyStyle(fontSize: 17, fontWeight: FontWeight.w500, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
