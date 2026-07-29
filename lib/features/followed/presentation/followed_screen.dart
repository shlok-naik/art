import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';

class FollowedScreen extends StatelessWidget {
  const FollowedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(context, 'Followed'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups_outlined, size: 56, color: kAccentColor),
                const SizedBox(height: 12),
                Text(
                  'Follow other artists to see their posts here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chewy(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
