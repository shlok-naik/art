import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_spacing.dart';
import 'app_styles.dart';

export 'app_spacing.dart';

/// Root [ThemeData] for the app: comic-panel color scheme (white/black
/// surface, hard borders, [kAccentColor] deep-orange reserved for CTAs/active
/// states) and component defaults so a bare [Text]/[TextField]/[AppBar]/
/// button/etc. already matches the hand-styled helpers in `app_styles.dart`
/// instead of falling back to Material defaults. Screen-level code should
/// keep preferring the helpers below for anything bespoke — this is the
/// floor everything else inherits from.
///
/// Built for a specific [brightness] (rather than reading the mutable
/// [appBrightness] global) because `MaterialApp` builds both `theme` and
/// `darkTheme` up front, independent of which one is active.
ThemeData buildAppTheme(Brightness brightness) {
  final palette = paletteFor(brightness);
  final isDark = brightness == Brightness.dark;
  final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
    bodyColor: palette.ink,
    displayColor: palette.ink,
  );

  final colorScheme = (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
    brightness: brightness,
    primary: kAccentColor,
    onPrimary: Colors.white,
    secondary: palette.border,
    onSecondary: Colors.white,
    tertiary: kGoldColor,
    onTertiary: palette.ink,
    surface: palette.surface,
    onSurface: palette.ink,
    surfaceContainerHighest: palette.surface,
    error: isDark ? Colors.red.shade300 : Colors.red.shade700,
    onError: Colors.white,
    outline: palette.border,
    outlineVariant: palette.hairline,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
    textTheme: textTheme.copyWith(
      headlineLarge: textTheme.headlineLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
      headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      titleLarge: textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
      titleMedium: textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      titleSmall: textTheme.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: palette.muted),
      labelLarge: textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      labelMedium: textTheme.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
      labelSmall: textTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: palette.muted),
    ),
    iconTheme: IconThemeData(color: palette.ink),
    dividerTheme: DividerThemeData(color: palette.hairline, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface,
      surfaceTintColor: palette.surface,
      elevation: 0,
      foregroundColor: palette.ink,
      iconTheme: IconThemeData(color: palette.ink),
      titleTextStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 24, color: palette.ink),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border, width: kBorderWidth),
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccentColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kAccentColor.withValues(alpha: 0.5),
        elevation: 0,
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16, horizontal: AppSpacing.space24),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kAccentColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        side: BorderSide(color: palette.border, width: kBorderWidth),
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kAccentColor,
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.ink,
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: GoogleFonts.chewy(color: palette.muted, fontSize: 16),
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        borderSide: BorderSide(color: palette.border, width: kBorderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        borderSide: BorderSide(color: palette.border, width: kBorderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        borderSide: const BorderSide(color: kAccentColor, width: kBorderWidth),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border, width: kBorderWidth),
        borderRadius: BorderRadius.circular(AppSpacing.space16),
      ),
      titleTextStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20, color: palette.ink),
      contentTextStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14, color: palette.ink),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.space24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.ink,
      contentTextStyle: GoogleFonts.nunito(color: palette.surface, fontWeight: FontWeight.w600, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.space8)),
    ),
    checkboxTheme: CheckboxThemeData(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kAccentColor : null,
      ),
    ),
    switchTheme: SwitchThemeData(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // The thumb needs to read as a distinct circle against the track, not
      // blend into it — a black thumb (fixed, not theme-flipped) always
      // shows up clearly against the orange "on" track; the ink-colored
      // thumb when "off" stays visible against the neutral track in both
      // themes.
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.black : palette.ink,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kAccentColor : palette.hairline,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.transparent : palette.border,
      ),
    ),
    radioTheme: RadioThemeData(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kAccentColor : null,
      ),
    ),
  );
}

/// Shimmer sweep used by every [AppSkeleton*] placeholder — a soft
/// left-to-right highlight over a muted base, looping continuously so a
/// loading section reads as "alive" rather than frozen.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child, this.onDark = false});

  final Widget child;
  final bool onDark;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = widget.onDark ? Colors.white.withValues(alpha: 0.28) : Colors.white;
    final base = widget.onDark ? Colors.white.withValues(alpha: 0.12) : kSurfaceColor;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final sweep = _controller.value;
            return LinearGradient(
              begin: Alignment(-1 - sweep * 3, 0),
              end: Alignment(1 - sweep * 3 + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single shimmering rectangle — the base building block for every other
/// skeleton shape below.
class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({super.key, this.width, this.height = 14, this.radius = 6, this.onDark = false});

  final double? width;
  final double height;
  final double radius;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      onDark: onDark,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: onDark ? Colors.white.withValues(alpha: 0.12) : kSurfaceColor,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// A shimmering circle, for avatar/photo placeholders.
class AppSkeletonCircle extends StatelessWidget {
  const AppSkeletonCircle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: kSurfaceColor, shape: BoxShape.circle),
      ),
    );
  }
}

/// One shimmering text-line placeholder.
class AppSkeletonLine extends StatelessWidget {
  const AppSkeletonLine({super.key, this.width, this.height = 12});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => AppSkeletonBox(width: width, height: height, radius: height / 2);
}

/// Avatar + two lines, mimicking a feed post / comment / chat message row.
/// Repeat a handful of these in place of a spinner for list-shaped content.
class AppSkeletonListTile extends StatelessWidget {
  const AppSkeletonListTile({super.key, this.showAvatar = true});

  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showAvatar) ...[
            const AppSkeletonCircle(size: 44),
            const SizedBox(width: AppSpacing.space8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSkeletonLine(width: MediaQuery.sizeOf(context).width * 0.5),
                const SizedBox(height: AppSpacing.space4),
                AppSkeletonLine(width: MediaQuery.sizeOf(context).width * 0.3, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic full-content loading placeholder: a handful of list-tile-shaped
/// rows. Drop this in wherever a screen previously showed a lone spinner
/// for a list/feed/chat body — it reads the shape of the content that's
/// about to arrive instead of a blank spinning wait.
class AppSkeletonScreen extends StatelessWidget {
  const AppSkeletonScreen({super.key, this.rows = 5, this.padding = const EdgeInsets.all(AppSpacing.space16)});

  final int rows;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < rows; i++) const AppSkeletonListTile()],
      ),
    );
  }
}

/// A single card-shaped shimmer block, for compact inline loading states
/// (a chart, a stat strip, a small section) where a full list of rows would
/// be too tall. Set [onDark] on black-background screens (voting feed,
/// wrapped) so the shimmer stays visible against the dark backdrop.
class AppSkeletonBlock extends StatelessWidget {
  const AppSkeletonBlock({super.key, this.height = 120, this.onDark = false});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) =>
      AppSkeletonBox(width: double.infinity, height: height, radius: kCardRadius, onDark: onDark);
}
