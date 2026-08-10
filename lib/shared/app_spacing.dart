/// The app's spacing grid: every margin/padding/gap should come from here
/// instead of a one-off number, so spacing stays on a consistent 4px
/// rhythm. Named by pixel value rather than a semantic tier (no
/// "medium"-vs-"large" bikeshedding) — pick the constant matching the gap
/// you want. Kept dependency-free so both `app_styles.dart` and
/// `app_theme.dart` (which needs the former for its color constants) can
/// import it without a cycle.
abstract final class AppSpacing {
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
}

/// Minimum hit-target side length (logical pixels) for any tappable control.
const double kMinTouchTarget = 48.0;
