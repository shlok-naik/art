import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';

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
    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'League'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThemeBanner(),
                const SizedBox(height: 24),
                _PastChampionCard(),
                const SizedBox(height: 24),
                Text(
                  'Submissions',
                  style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vote for your favorite — no self-voting!',
                  style: GoogleFonts.chewy(fontSize: 15, color: Colors.black54),
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
      decoration: appCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "THIS SESSION'S THEME",
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 14, color: kAccentColor),
          ),
          const SizedBox(height: 4),
          Text(_themeTitle, style: appHeadlineStyle(fontSize: 44)),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Text(
              _themeDescription,
              style: GoogleFonts.chewy(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.black, size: 20),
              const SizedBox(width: 6),
              Text(_timeRemaining, style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16)),
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
      decoration: appCardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: kAccentColor, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last Season\'s Champion',
                  style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '@lunar_art — "Underwater Ruins"',
                  style: GoogleFonts.chewy(fontSize: 15),
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
      decoration: appCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Image',
                  style: GoogleFonts.chewy(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black38),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@$artist',
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: const BorderSide(color: kBorderColor, width: kBorderWidth),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  icon: const Icon(Icons.favorite_border, size: 16),
                  label: Text(
                    '$votes',
                    style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
