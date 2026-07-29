import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../shell/main_shell.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Go Pro'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'UPGRADE TO',
                        style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                      ),
                      Text('PRO', style: appHeadlineStyle(fontSize: 56)),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: Text(
                          'Unlock the full studio.',
                          style: GoogleFonts.chewy(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _FeatureCard(
                  icon: Icons.groups,
                  title: 'Multiple leagues',
                  description: 'Join and compete in as many leagues at once as you want.',
                ),
                const SizedBox(height: 12),
                const _FeatureCard(
                  icon: Icons.insights,
                  title: 'Deeper analytics',
                  description:
                      'Time spent per stage, and how you\'re improving across your projects over time.',
                ),
                const SizedBox(height: 12),
                const _ArtWrappedCard(),
                const SizedBox(height: 20),
                const _PriceCard(),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: 'Upgrade to Pro',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon')),
                    );
                  },
                ),
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.chewy(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtWrappedCard extends StatelessWidget {
  const _ArtWrappedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: kAccentColor, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Art Wrapped',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Placeholder for the hero illustration — swap for a generated
              // asset (see the image-gen prompt shared alongside this screen).
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Your Year in Art',
                  style: GoogleFonts.chewy(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black38),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your annual recap: total hours logged, favorite and most-used '
                'stage, tools you reached for most, trophies won, and how many '
                'projects you finished — rendered as a shareable slideshow you '
                'can post anywhere.',
                style: GoogleFonts.chewy(fontSize: 15),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: kAccentColor,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Text(
                'NEW',
                style: GoogleFonts.chewy(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(),
      child: Column(
        children: [
          Text('\$4.99/mo', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 32)),
          const SizedBox(height: 4),
          Text('Cancel anytime', style: GoogleFonts.chewy(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }
}
