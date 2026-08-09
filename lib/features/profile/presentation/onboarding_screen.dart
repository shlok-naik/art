import 'package:flutter/material.dart';

import '../../../shared/app_spacing.dart';
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

  /// The first page carries the wordmark hero in place of the old mascot
  /// illustration; the rest are plain title + body.
  static const _pages = [
    (
      title: 'Welcome',
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Skip',
                    style: appBodyStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kNavyColor),
                  ),
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
                        if (index == 0) ...[
                          const AppWordmark(fontSize: 40),
                          const SizedBox(height: AppSpacing.space28),
                        ],
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: appBodyStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: appBodyStyle(fontSize: 15, color: kMutedColor).copyWith(height: 1.5),
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
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                      decoration: BoxDecoration(
                        color: index == _page ? kAccentColor : kHairlineColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space20),
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
