import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../../auth/providers.dart';
import '../../posts/presentation/my_posts_screen.dart';
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
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No profile found.',
                    style: GoogleFonts.chewy(fontSize: 16, color: Colors.black),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            side: const BorderSide(color: kBorderColor, width: kBorderWidth),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.grid_view_outlined),
                          label: const Text('My Posts'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppErrorText('Error: $error'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
