import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/profile_view_screen.dart';
import '../../profile/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final username = profileAsync.value?.username ?? 'user';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      CircleAvatar(radius: 10, backgroundColor: Colors.deepOrange),
                      SizedBox(width: 8),
                      Text(
                        'UNFINISHED',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                    child: const Text('Buy Pro'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: _PillButton(label: 'League')),
                  SizedBox(width: 4),
                  Expanded(child: _PillButton(label: 'Analytics')),
                  SizedBox(width: 4),
                  Expanded(child: _PillButton(label: 'My Posts')),
                  SizedBox(width: 4),
                  Expanded(child: _PillButton(label: 'Projects')),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'WELCOME',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.deepOrange,
                      ),
                    ),
                    Text(
                      '@$username',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    const Text('Ready to create a masterpiece?'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_outline, color: Colors.deepOrange, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Continue Last Project', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Name    Stage [stage]'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Center(
                child: Text(
                  'Most Recent Post',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Center(
                  child: Text('Image', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('Reactions Counter')),
              const SizedBox(height: 16),
              const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Views    Date'),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home, label: 'Home', onTap: () {}),
            _NavItem(icon: Icons.article_outlined, label: 'Feed', onTap: () {}),
            _NavItem(
              icon: Icons.edit,
              label: '',
              onTap: () {},
              highlighted: true,
            ),
            _NavItem(icon: Icons.groups_outlined, label: 'Followed', onTap: () {}),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileViewScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: highlighted ? 22 : 16,
            backgroundColor: highlighted ? Colors.deepOrange : Colors.transparent,
            child: Icon(icon, color: highlighted ? Colors.white : Colors.black),
          ),
          if (label.isNotEmpty) Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
