import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../profile/presentation/profile_view_screen.dart';
import '../../profile/providers.dart';

const _borderColor = Colors.black;
const _borderWidth = 2.0;
const _sidePadding = EdgeInsets.symmetric(horizontal: 16);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final username = profileAsync.value?.username ?? 'user';

    return DefaultTextStyle(
      style: GoogleFonts.chewy(color: Colors.black),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: _sidePadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/branding/logo.png', height: 60),
                      _OutlinedPillButton(
                        label: 'Buy Pro',
                        onPressed: () {},
                        fontSize: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: _sidePadding,
                  child: Row(
                    children: [
                      Expanded(child: _PillButton(label: 'League')),
                      const SizedBox(width: 4),
                      Expanded(child: _PillButton(label: 'Analytics')),
                      const SizedBox(width: 4),
                      Expanded(child: _PillButton(label: 'My Posts')),
                      const SizedBox(width: 4),
                      Expanded(child: _PillButton(label: 'Projects')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: _sidePadding,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'WELCOME',
                          style: GoogleFonts.sedgwickAveDisplay(
                            fontSize: 84,
                            height: 1.0,
                            color: Colors.deepOrange,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -14),
                          child: Text(
                            '@$username',
                            style: GoogleFonts.rubikMonoOne(fontSize: 56, color: Colors.black),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -22),
                          child: Text(
                            'Ready to create a masterpiece?',
                            style: GoogleFonts.chewy(fontSize: 22),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Transform (not negative padding, which Flutter's Padding widget
                // rejects at runtime) shifts this card to bleed past the screen's left
                // edge; it's sized to fit its content rather than stretching full width.
                Transform.translate(
                  offset: const Offset(-10, 0),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderColor, width: _borderWidth),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_circle_outline, color: Colors.deepOrange, size: 44),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Continue Last Project',
                                  style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 26),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Name    Stage [stage]',
                                  style: GoogleFonts.chewy(fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: _sidePadding,
                  child: Center(
                    child: Text(
                      'Most Recent Post',
                      style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: _sidePadding,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderColor, width: _borderWidth),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 165,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Text(
                                  'Image',
                                  style: GoogleFonts.chewy(fontSize: 54, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Reactions Counter',
                                  style: GoogleFonts.chewy(color: Colors.white, fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Title', style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('Views    Date', style: GoogleFonts.chewy(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SizedBox(
          height: 104,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              BottomAppBar(
                color: Colors.white,
                height: 104,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(icon: Icons.home, label: 'Home', onTap: () {}),
                    _NavItem(icon: Icons.article_outlined, label: 'Feed', onTap: () {}),
                    const SizedBox(width: 70),
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
              // Sized and positioned to intentionally overflow past the bottom of the
              // screen, so the mascot's legs/feet run off the edge.
              Positioned(
                bottom: -32,
                child: GestureDetector(
                  onTap: () {},
                  child: Image.asset('assets/branding/mascot.png', height: 150),
                ),
              ),
            ],
          ),
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
    return _OutlinedPillButton(
      label: label,
      onPressed: () {},
      fontSize: 15,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

class _OutlinedPillButton extends StatelessWidget {
  const _OutlinedPillButton({
    required this.label,
    required this.onPressed,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final String label;
  final VoidCallback onPressed;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: const BorderSide(color: _borderColor, width: _borderWidth),
        foregroundColor: Colors.black,
        padding: padding,
        textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: fontSize),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = CircleAvatar(
      radius: 16,
      backgroundColor: Colors.transparent,
      child: Icon(icon, color: Colors.black),
    );

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (label.isNotEmpty) Text(label, style: GoogleFonts.chewy(fontSize: 12)),
        ],
      ),
    );
  }
}
