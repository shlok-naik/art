import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../shell/main_shell.dart';
import 'art_wrapped_screen.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'Go Pro'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'UPGRADE TO',
                      style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF888888)),
                    ),
                    Text('PRO', style: appHeadlineStyle(fontSize: 52)),
                    const SizedBox(height: 4),
                    Text(
                      'Unlock the full studio.',
                      style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _FeatureCard(
                emoji: '👥',
                title: 'Multiple leagues',
                description: 'Join and compete in as many leagues at once as you want.',
              ),
              const SizedBox(height: 12),
              const _FeatureCard(
                emoji: '📊',
                title: 'Deeper analytics',
                description: "Time spent per stage, and how you're improving over time.",
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ArtWrappedScreen()),
                ),
                child: const _ArtWrappedCard(),
              ),
              const SizedBox(height: 16),
              const _PriceCard(),
              const SizedBox(height: 16),
              _UpgradeButton(
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
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.emoji, required this.title, required this.description});

  final String emoji;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: GoogleFonts.chewy(fontSize: 17, color: Colors.black)),
                const SizedBox(height: 2),
                Text(description, style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF555555))),
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
      padding: const EdgeInsets.all(14),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Art Wrapped', style: GoogleFonts.chewy(fontSize: 19, color: Colors.black)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Placeholder for the hero illustration — swap for a generated
              // asset (see the image-gen prompt shared alongside this screen).
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Your Year in Art',
                  style: GoogleFonts.chewy(fontSize: 16, color: Colors.black38),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Hours logged, favorite tools, trophies won — rendered as a shareable slideshow.',
                style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF555555)),
              ),
            ],
          ),
          Positioned(
            top: -14,
            right: -14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: kAccentColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                'NEW',
                style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
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
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 3),
      child: Column(
        children: [
          Text('\$4.99/mo', style: appBodyStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black)),
          const SizedBox(height: 2),
          Text('Cancel anytime', style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF888888))),
        ],
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: kAccentColor,
          border: Border.all(color: kBorderColor, width: kBorderWidth),
          borderRadius: BorderRadius.circular(24),
          boxShadow: hardShadow(offset: 4),
        ),
        alignment: Alignment.center,
        child: Text('Upgrade to Pro', style: GoogleFonts.chewy(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
