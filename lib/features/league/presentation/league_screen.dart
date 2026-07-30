import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_bottom_nav.dart';
import '../../../shared/app_styles.dart';
import '../../shell/main_shell.dart';

// Static placeholder data. Replace with real contest/submission/vote data
// once the league backend lands.
const _themeTitle = 'Neon Dreams';
const _themeDescription =
    'Paint a scene lit entirely by neon — cities, creatures, or anything that glows.';
const _timeRemaining = '3d 14h left';

const _submissions = [
  {'artist': 'mika_draws', 'votes': 128},
  {'artist': 'inkwell_jo', 'votes': 97},
  {'artist': 'pixel_finch', 'votes': 84},
  {'artist': 'crimson.doe', 'votes': 61},
  {'artist': 'lunar_art', 'votes': 45},
  {'artist': 'sketchy_sam', 'votes': 12},
];

class LeagueScreen extends StatelessWidget {
  const LeagueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appThemedAppBar(context, 'League'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ThemeBanner(),
              const SizedBox(height: 16),
              const _PastChampionCard(),
              const SizedBox(height: 20),
              Text('Submissions', style: GoogleFonts.chewy(fontSize: 18, color: Colors.black)),
              const SizedBox(height: 2),
              Text(
                'Vote for your favorite — no self-voting!',
                style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF888888)),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _submissions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final submission = _submissions[index];
                  return _SubmissionCard(
                    artist: submission['artist'] as String,
                    votes: submission['votes'] as int,
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

class _ThemeBanner extends StatelessWidget {
  const _ThemeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: appHardCardDecoration(radius: 18, color: kAccentTintColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "THIS SESSION'S THEME",
            style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kAccentColor),
          ),
          const SizedBox(height: 4),
          Text(_themeTitle, style: appHeadlineStyle(fontSize: 38)),
          const SizedBox(height: 2),
          Text(
            _themeDescription,
            style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF444444)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.black, size: 18),
              const SizedBox(width: 6),
              Text(_timeRemaining, style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PastChampionCard extends StatelessWidget {
  const _PastChampionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: appHardCardDecoration(radius: 18),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Last Season's Champion", style: GoogleFonts.chewy(fontSize: 16, color: Colors.black)),
                Text(
                  '@lunar_art — "Underwater Ruins"',
                  style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF555555)),
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

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.artist, required this.votes});

  final String artist;
  final int votes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: appHardCardDecoration(radius: 14, shadowOffset: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Image',
                  style: GoogleFonts.chewy(fontSize: 20, color: Colors.black38),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@$artist',
            style: GoogleFonts.chewy(fontSize: 14, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: kBorderColor, width: kBorderWidth),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text('$votes', style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
