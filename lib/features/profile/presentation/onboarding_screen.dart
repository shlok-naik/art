import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    (
      title: "Hey, I'm Bud 👋",
      body: "Let's set up your profile in under a minute.",
    ),
    (
      title: 'Track every step',
      body: 'Log sessions as your art comes together, from sketch to finishing touches.',
    ),
    (
      title: 'Share your progress',
      body: 'Post your work, celebrate your streak, and connect with other artists.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      widget.onComplete();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text('Skip', style: GoogleFonts.chewy(color: kInkColor, fontSize: 15)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.flip(
                          flipX: true,
                          child: Image.asset('assets/branding/mascot.png', height: 150),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.chewy(fontSize: 27, color: kInkColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: appBodyStyle(fontSize: 16, color: const Color(0xFF666666)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < _pages.length; index++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == _page ? kAccentColor : const Color(0xFFE5DED4),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: _page == _pages.length - 1 ? 'Set up my profile' : 'Next',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
