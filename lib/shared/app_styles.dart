import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared look-and-feel constants matching the home screen's comic-panel
/// style: white/black background, black/white text+borders in the Chewy
/// font, and a deep orange accent (unchanged across themes).
///
/// Every brightness-dependent token below is a `Color get` rather than a
/// `const` so it can resolve against [appBrightness] at build time — that
/// keeps every existing call site (`color: kInkColor`, `BorderSide(color:
/// kBorderColor, ...)`, etc.) working unchanged while still flipping with
/// the dark-mode toggle. [appBrightness] is set once per app rebuild (see
/// `App.build` in `app.dart`) before the tree below it remounts, so plain
/// field-style reads here always see the brightness that's about to be
/// painted.
Brightness appBrightness = Brightness.light;

class AppPalette {
  const AppPalette({
    required this.border,
    required this.ink,
    required this.muted,
    required this.hairline,
    required this.surface,
    required this.accentTint,
    required this.successText,
    required this.successBg,
  });

  final Color border;
  final Color ink;
  final Color muted;
  final Color hairline;
  final Color surface;
  final Color accentTint;
  final Color successText;
  final Color successBg;
}

const _lightPalette = AppPalette(
  border: Color(0xFF111111),
  ink: Colors.black,
  muted: Colors.black54,
  hairline: Color(0xFFE0E0E0),
  surface: Colors.white,
  accentTint: Color(0xFFFFF1EA),
  successText: Color(0xFF2E9E4E),
  successBg: Color(0xFFE8F7EC),
);

const _darkPalette = AppPalette(
  border: Color(0xFFE6E6E6),
  ink: Colors.white,
  muted: Colors.white60,
  hairline: Color(0xFF2C2C2C),
  surface: Color(0xFF161616),
  accentTint: Color(0xFF3B2416),
  successText: Color(0xFF6FDB8F),
  successBg: Color(0xFF17301F),
);

/// The full token set for [brightness] — used directly by `buildAppTheme`
/// (which needs both palettes at once to build `theme`/`darkTheme`) so its
/// colors don't depend on the mutable [appBrightness] global below.
AppPalette paletteFor(Brightness brightness) => brightness == Brightness.dark ? _darkPalette : _lightPalette;

AppPalette get _palette => paletteFor(appBrightness);

/// Hard border color — black in light mode, near-white in dark mode.
Color get kBorderColor => _palette.border;
const kBorderWidth = 2.0;
const kAccentColor = Colors.deepOrange;

/// Accent-tinted background used for banners/callouts (streak card, theme
/// banner, "Go Pro" tile, follow-state chips).
Color get kAccentTintColor => _palette.accentTint;

/// "Finished"/success status color pair (chip text on chip background).
Color get kSuccessTextColor => _palette.successText;
Color get kSuccessBgColor => _palette.successBg;

/// Dark chrome color reserved for the bottom tab bar and other black-on-white
/// accents — kept as its own token (mapped onto the comic-panel black/white
/// scheme) so newer screens built against it don't need per-call-site edits.
Color get kNavyColor => kBorderColor;

/// Primary ink color for body text — black in light mode, white in dark
/// mode, matching the comic-panel look everywhere text isn't the orange
/// accent.
Color get kInkColor => _palette.ink;

/// Secondary/muted text color for captions, labels, and meta text.
Color get kMutedColor => _palette.muted;

/// Subtle hairline used sparingly for internal dividers. The comic-panel
/// look mostly relies on [kBorderColor] hard borders instead, so this stays
/// low-contrast and out of the way.
Color get kHairlineColor => _palette.hairline;

/// Neutral card/surface fill — white in light mode, dark grey in dark mode
/// (bordered in black/white rather than tinted grey).
Color get kSurfaceColor => _palette.surface;

/// Reserved for trophy/rank accents (league trophies, achievement badges) —
/// unchanged across themes.
const kGoldColor = Color(0xFFC9A227);

/// Standard rounding applied to cards, buttons, and input fields.
const kCardRadius = 12.0;

/// Card border color — same hard border as [kBorderColor].
Color get kCardBorderColor => kBorderColor;

TextStyle appHeadlineStyle({
  double fontSize = 56,
  Color color = kAccentColor,
  FontWeight fontWeight = FontWeight.normal,
  bool italic = false,
}) {
  return GoogleFonts.chewy(
    fontSize: fontSize,
    height: 1.05,
    fontWeight: fontWeight,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
  );
}

/// The "Unfinished" text wordmark. Screens that showed the raster
/// logo/mascot artwork keep using those assets directly; this stays around
/// for spots that were built against a plain text mark.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.fontSize = 26, this.color});

  final double fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Unfinished',
      style: appHeadlineStyle(fontSize: fontSize, color: color ?? kInkColor),
    );
  }
}

/// Nunito is used for body copy, stats, numbers and meta text so Chewy stays
/// reserved for headlines, buttons and nav labels.
TextStyle appBodyStyle({
  double fontSize = 15,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  FontStyle fontStyle = FontStyle.normal,
}) {
  return GoogleFonts.nunito(
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    color: color ?? kInkColor,
  );
}

/// Flat "hard shadow" (offset only, no blur) used on virtually every card and
/// button in the comic-panel look — replaces plain unshadowed borders.
List<BoxShadow> hardShadow({double offset = 4}) {
  return [BoxShadow(color: kBorderColor, offset: Offset(offset, offset), blurRadius: 0)];
}

/// Flat card fill kept for call sites built against the surface-tint look;
/// now boxed with the same hard black border as [appHardCardDecoration] so
/// it reads consistently with the comic-panel style.
BoxDecoration appFlatCardDecoration({double radius = kCardRadius, Color? color}) {
  return BoxDecoration(
    color: color ?? kSurfaceColor,
    border: Border.all(color: kBorderColor, width: kBorderWidth),
    borderRadius: BorderRadius.circular(radius),
  );
}

/// Card decoration matching the comic-panel look: 2px hard border, rounded
/// corners and a hard shadow.
BoxDecoration appHardCardDecoration({
  double radius = 18,
  double shadowOffset = 4,
  Color? color,
}) {
  return BoxDecoration(
    color: color ?? kSurfaceColor,
    border: Border.all(color: kBorderColor, width: kBorderWidth),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: hardShadow(offset: shadowOffset),
  );
}

AppBar appThemedAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: kSurfaceColor,
    surfaceTintColor: kSurfaceColor,
    elevation: 0,
    foregroundColor: kInkColor,
    iconTheme: IconThemeData(color: kInkColor),
    title: Text(title, style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 24, color: kInkColor)),
    actions: actions,
  );
}

InputDecoration appInputDecoration(String label) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: kBorderColor, width: kBorderWidth),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.chewy(color: kMutedColor, fontSize: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(borderSide: const BorderSide(color: kAccentColor, width: kBorderWidth)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

BoxDecoration appCardDecoration({double radius = 12}) {
  return BoxDecoration(
    border: Border.all(color: kBorderColor, width: kBorderWidth),
    borderRadius: BorderRadius.circular(radius),
  );
}

/// Full-width filled pill button for primary actions (e.g. "Log in", "Save").
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({super.key, required this.label, required this.onPressed, this.isLoading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kAccentColor.withValues(alpha: 0.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

/// Outlined black-bordered pill button, matching the home screen's nav pills.
class AppOutlinedPillButton extends StatelessWidget {
  const AppOutlinedPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide(color: kBorderColor, width: kBorderWidth),
        foregroundColor: kInkColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: fontSize),
      ),
      child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }
}

class AppErrorText extends StatelessWidget {
  const AppErrorText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.chewy(color: Colors.red.shade700, fontSize: 15),
      textAlign: TextAlign.center,
    );
  }
}

/// A human-readable message for a failed request. Network-level failures
/// (offline, DNS, refused connection, timeout) get a friendly explanation
/// instead of a raw exception string; anything else falls back to the raw
/// error so real bugs stay diagnosable.
String appErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection refused') ||
      text.contains('Connection failed') ||
      text.contains('ClientException') ||
      text.contains('Network is unreachable')) {
    return 'No internet connection — check your network and try again.';
  }
  if (text.contains('TimeoutException') || text.contains('timed out')) {
    return 'The server took too long to respond — try again in a moment.';
  }
  return text;
}

/// The app-wide terminal error state for a failed async load: friendly
/// message (via [appErrorMessage]) plus an optional Retry action, so no
/// screen dead-ends on a raw error string or an endless spinner. Use
/// [onDark] on black-background screens (feed, voting feed).
class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.error, this.onRetry, this.onDark = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    // `onDark` covers screens that are intentionally always-black regardless
    // of the app theme (feed, voting feed); fold in the app-wide toggle too
    // so this state reads correctly on ordinary screens in dark mode.
    final isDark = onDark || appBrightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: isDark ? Colors.white38 : Colors.black26),
            const SizedBox(height: 10),
            Text(
              appErrorMessage(error),
              textAlign: TextAlign.center,
              style: GoogleFonts.chewy(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.red.shade700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: BorderSide(color: isDark ? Colors.white : kBorderColor, width: kBorderWidth),
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon + label + value row used by the post detail screen and the feed's
/// details sheet. [icon] is optional so call sites that only have a
/// label/value pair (no natural glyph) can skip it.
class AppDetailStat extends StatelessWidget {
  const AppDetailStat({super.key, this.icon, required this.label, required this.value});

  final IconData? icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.chewy(fontSize: 12, color: kMutedColor)),
        Text(value, style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15, color: kInkColor)),
      ],
    );
    if (icon == null) return textColumn;
    return Row(
      children: [
        Icon(icon, size: 20, color: kAccentColor),
        const SizedBox(width: 8),
        textColumn,
      ],
    );
  }
}

/// Big-number-over-label column used by the profile screens' Posts /
/// Followers / Following (or League rank) strip.
class AppStatColumn extends StatelessWidget {
  const AppStatColumn({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInkColor)),
        const SizedBox(height: 2),
        Text(label, style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF888888))),
      ],
    );
  }
}
