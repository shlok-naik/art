import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared look-and-feel constants for the navy/cobalt flat redesign: white
/// background, navy chrome (app bars, bottom nav), flat filled cards, Inter
/// body text with Fraunces reserved for a few "creative content" headlines.
const kNavyColor = Color(0xFF16233E);
const kInkColor = Color(0xFF1B2740);
const kMutedColor = Color(0xFF6B7280);
const kHairlineColor = Color(0xFFE7EAF2);
const kSurfaceColor = Color(0xFFF6F7FA);
const kAccentColor = Color(0xFF2E5EFF);

/// Standard rounding applied to cards, buttons, and input fields.
const kCardRadius = 12.0;

/// Subtle card outline — replaces the old hard 2px black border on
/// appHardCardDecoration.
const kCardBorderColor = Color(0xFFE5E7EB);

/// Pre-redesign border constants — used directly by badges, chart outlines,
/// and image frames that intentionally keep the bolder accent look.
const kBorderColor = Color(0xFF111111);
const kBorderWidth = 2.0;

/// Accent-tinted background used for banners/callouts (streak badge, theme
/// banner, "Go Pro" tile, follow-state chips).
const kAccentTintColor = Color(0xFFEEF2FF);

/// "Finished"/success status color pair (chip text on chip background).
const kSuccessTextColor = Color(0xFF2E9E4E);
const kSuccessBgColor = Color(0xFFE8F7EC);

/// Fraunces serif — kept only for "creative content" headlines (league theme
/// title, project titles); everything else is Inter.
TextStyle appHeadlineStyle({double fontSize = 28, Color color = kInkColor}) {
  return GoogleFonts.fraunces(fontSize: fontSize, height: 1.1, fontWeight: FontWeight.w500, color: color);
}

TextStyle appBodyStyle({
  double fontSize = 15,
  FontWeight fontWeight = FontWeight.w400,
  Color color = kInkColor,
}) {
  return GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color);
}

/// Flat filled card — the redesign's standard card treatment, replacing
/// appHardCardDecoration's white+border look on every covered screen.
BoxDecoration appFlatCardDecoration({double radius = kCardRadius, Color color = kSurfaceColor}) =>
    BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius));

/// Soft, low-blur shadow used on white cards in place of the old hard offset
/// shadow — barely-there depth instead of a drawn outline.
List<BoxShadow> hardShadow({double offset = 4}) {
  return [BoxShadow(color: Colors.black.withValues(alpha: 0.04), offset: Offset(0, offset / 2), blurRadius: 10)];
}

/// Card decoration for the redesigned screens: a subtle grey outline, rounded
/// corners and a soft shadow. Kept separate from [appCardDecoration] (used by
/// screens outside this redesign) so existing plain-bordered screens are unaffected.
BoxDecoration appHardCardDecoration({
  double radius = kCardRadius,
  double shadowOffset = 4,
  Color color = Colors.white,
}) {
  return BoxDecoration(
    color: color,
    border: Border.all(color: kCardBorderColor, width: 1),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: hardShadow(offset: shadowOffset),
  );
}

AppBar appThemedAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: kNavyColor,
    surfaceTintColor: kNavyColor,
    elevation: 0,
    foregroundColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.white),
    title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white)),
    actions: actions,
  );
}

InputDecoration appInputDecoration(String label) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(kCardRadius),
    borderSide: BorderSide.none,
  );
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(color: kMutedColor, fontSize: 14, fontWeight: FontWeight.w500),
    filled: true,
    fillColor: kSurfaceColor,
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

BoxDecoration appCardDecoration({double radius = kCardRadius}) {
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
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
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

/// Flat surface pill button — the redesign's secondary action (log out,
/// preview profile). Name kept from the old outlined version so existing
/// call sites restyle without a rename.
class AppOutlinedPillButton extends StatelessWidget {
  const AppOutlinedPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fontSize = 13,
  });

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        shape: const StadiumBorder(),
        backgroundColor: kSurfaceColor,
        foregroundColor: kInkColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fontSize),
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
      style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 14, fontWeight: FontWeight.w500),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: onDark ? Colors.white38 : kMutedColor),
            const SizedBox(height: 10),
            Text(
              appErrorMessage(error),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: onDark ? Colors.white : Colors.red.shade700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: onDark ? Colors.white24 : kSurfaceColor,
                  foregroundColor: onDark ? Colors.white : kInkColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
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
/// details sheet.
class AppDetailStat extends StatelessWidget {
  const AppDetailStat({super.key, required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kAccentColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: kMutedColor)),
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: kInkColor)),
          ],
        ),
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
        Text(value, style: appBodyStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(label, style: appBodyStyle(fontSize: 10, color: kMutedColor)),
      ],
    );
  }
}
