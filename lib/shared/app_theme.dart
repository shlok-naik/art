import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_spacing.dart';
import 'app_styles.dart';

export 'app_spacing.dart';

/// Root [ThemeData] for the app: comic-panel color scheme (white surface,
/// black hard borders, [kAccentColor] deep-orange reserved for CTAs/active
/// states) and component defaults so a bare [Text]/[TextField]/[AppBar]/
/// button/etc. already matches the hand-styled helpers in `app_styles.dart`
/// instead of falling back to Material defaults. Screen-level code should
/// keep preferring the helpers below for anything bespoke — this is the
/// floor everything else inherits from.
ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).apply(
    bodyColor: kInkColor,
    displayColor: kInkColor,
  );

  final colorScheme = const ColorScheme.light().copyWith(
    brightness: Brightness.light,
    primary: kAccentColor,
    onPrimary: Colors.white,
    secondary: kNavyColor,
    onSecondary: Colors.white,
    tertiary: kGoldColor,
    onTertiary: kInkColor,
    surface: Colors.white,
    onSurface: kInkColor,
    surfaceContainerHighest: kSurfaceColor,
    error: Colors.red.shade700,
    onError: Colors.white,
    outline: kCardBorderColor,
    outlineVariant: kHairlineColor,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
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
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
      labelLarge: textTheme.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      labelMedium: textTheme.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
      labelSmall: textTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: kMutedColor),
    ),
    iconTheme: const IconThemeData(color: kInkColor),
    dividerTheme: const DividerThemeData(color: kHairlineColor, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      foregroundColor: kInkColor,
      iconTheme: const IconThemeData(color: kInkColor),
      titleTextStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 24, color: kInkColor),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: kBorderColor, width: kBorderWidth),
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
        foregroundColor: kInkColor,
        side: const BorderSide(color: kBorderColor, width: kBorderWidth),
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
        foregroundColor: kInkColor,
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: GoogleFonts.chewy(color: Colors.black54, fontSize: 16),
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        borderSide: const BorderSide(color: kBorderColor, width: kBorderWidth),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        borderSide: const BorderSide(color: kBorderColor, width: kBorderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kCardRadius),
        borderSide: const BorderSide(color: kAccentColor, width: kBorderWidth),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: kBorderColor, width: kBorderWidth),
        borderRadius: BorderRadius.circular(AppSpacing.space16),
      ),
      titleTextStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 20, color: kInkColor),
      contentTextStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14, color: kInkColor),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.space24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kInkColor,
      contentTextStyle: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kAccentColor : null,
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
        decoration: const BoxDecoration(color: kSurfaceColor, shape: BoxShape.circle),
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
