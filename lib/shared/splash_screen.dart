import 'package:flutter/material.dart';

import 'app_styles.dart';

/// Loading screen shown while auth/profile state resolves at app start:
/// white background, the wordmark logo centered, and three dots pulsing in
/// sequence below it. Matches the native splash (flutter_native_splash,
/// configured in pubspec.yaml) so there's no visual flash on handoff.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/branding/logo.png', height: 52),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      _Dot(opacity: _dotOpacity(_controller.value, i)),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Cycles which dot is "lit": each dot takes its turn at full opacity for
  /// one third of the loop, fading the other two, so the row reads as a
  /// left-to-right pulse rather than three dots blinking in unison.
  double _dotOpacity(double t, int index) {
    final phase = (t - index / 3) % 1.0;
    if (phase < 1 / 3) return 1.0;
    if (phase < 2 / 3) return 0.45;
    return 0.2;
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: kAccentColor),
      ),
    );
  }
}
