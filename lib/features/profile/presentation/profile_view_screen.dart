import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';
import '../providers.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Text('No profile found.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display name: ${profile.displayName}'),
                Text('Username: ${profile.username}'),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) =>
              Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
