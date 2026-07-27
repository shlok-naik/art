import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../providers.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appThemedAppBar(
          context,
          'Profile',
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: profileAsync.when(
              data: (profile) {
                if (profile == null) {
                  return Text(
                    'No profile found.',
                    style: GoogleFonts.chewy(fontSize: 16, color: Colors.black),
                  );
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: appCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile.displayName,
                        style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${profile.username}',
                        style: GoogleFonts.chewy(fontSize: 18, color: kAccentColor),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppErrorText('Error: $error'),
            ),
          ),
        ),
      ),
    );
  }
}
