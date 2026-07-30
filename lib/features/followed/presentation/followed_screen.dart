import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';

// Placeholder suggested-artists list — replace once a follow-suggestion
// backend/repository exists.
const _suggestedArtists = [
  {'handle': 'mika_draws', 'posts': '312 posts'},
  {'handle': 'inkwell_jo', 'posts': '97 posts'},
];

class FollowedScreen extends StatelessWidget {
  const FollowedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Followed', style: GoogleFonts.chewy(fontSize: 24, color: Colors.black)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: appHardCardDecoration(radius: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/branding/mascot.png', height: 80),
                    const SizedBox(height: 10),
                    Text('Nobody here yet', style: GoogleFonts.chewy(fontSize: 18, color: Colors.black)),
                    const SizedBox(height: 4),
                    Text(
                      'Follow other artists to see their posts here.',
                      textAlign: TextAlign.center,
                      style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Suggested artists', style: GoogleFonts.chewy(fontSize: 16, color: Colors.black)),
              const SizedBox(height: 10),
              for (final artist in _suggestedArtists) ...[
                _SuggestedArtistTile(
                  handle: artist['handle']!,
                  posts: artist['posts']!,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedArtistTile extends StatelessWidget {
  const _SuggestedArtistTile({required this.handle, required this.posts});

  final String handle;
  final String posts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: appHardCardDecoration(radius: 16, shadowOffset: 2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(color: kBorderColor, width: kBorderWidth),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person, size: 22, color: Colors.black26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('@$handle', style: GoogleFonts.chewy(fontSize: 15, color: Colors.black), overflow: TextOverflow.ellipsis),
                Text(posts, style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF888888))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: kBorderColor, width: kBorderWidth),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Follow', style: appBodyStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
