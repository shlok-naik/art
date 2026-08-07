import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared look-and-feel constants matching the home screen's comic-panel style:
/// white background, black text/borders in the Chewy font, and a deep orange accent.
const kBorderColor = Color(0xFF111111);
const kBorderWidth = 2.0;
const kAccentColor = Colors.deepOrange;

/// Accent-tinted background used for banners/callouts (streak card, theme banner).
const kAccentTintColor = Color(0xFFFFF1EA);

/// "Finished"/success status color pair (chip text on chip background).
const kSuccessTextColor = Color(0xFF2E9E4E);
const kSuccessBgColor = Color(0xFFE8F7EC);

TextStyle appHeadlineStyle({double fontSize = 56, Color color = kAccentColor}) {
  return GoogleFonts.chewy(fontSize: fontSize, height: 1.05, color: color);
}

/// Nunito is used for body copy, stats, numbers and meta text so Chewy stays
/// reserved for headlines, buttons and nav labels.
TextStyle appBodyStyle({
  double fontSize = 15,
  FontWeight fontWeight = FontWeight.w600,
  Color color = Colors.black,
}) {
  return GoogleFonts.nunito(fontSize: fontSize, fontWeight: fontWeight, color: color);
}

/// Flat "hard shadow" (offset only, no blur) used on virtually every card and
/// button in the redesign — replaces plain unshadowed borders.
List<BoxShadow> hardShadow({double offset = 4}) {
  return [BoxShadow(color: kBorderColor, offset: Offset(offset, offset), blurRadius: 0)];
}

/// Card decoration for the redesigned screens: 2px black border, rounded
/// corners and a hard shadow. Kept separate from [appCardDecoration] (used by
/// screens outside this redesign) so existing plain-bordered screens are unaffected.
BoxDecoration appHardCardDecoration({
  double radius = 18,
  double shadowOffset = 4,
  Color color = Colors.white,
}) {
  return BoxDecoration(
    color: color,
    border: Border.all(color: kBorderColor, width: kBorderWidth),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: hardShadow(offset: shadowOffset),
  );
}

AppBar appThemedAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    foregroundColor: Colors.black,
    iconTheme: const IconThemeData(color: Colors.black),
    title: Text(title, style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
    actions: actions,
  );
}

InputDecoration appInputDecoration(String label) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: kBorderColor, width: kBorderWidth),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.chewy(color: Colors.black54, fontSize: 16),
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
        side: const BorderSide(color: kBorderColor, width: kBorderWidth),
        foregroundColor: Colors.black,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: onDark ? Colors.white38 : Colors.black26),
            const SizedBox(height: 10),
            Text(
              appErrorMessage(error),
              textAlign: TextAlign.center,
              style: GoogleFonts.chewy(
                fontSize: 15,
                color: onDark ? Colors.white : Colors.red.shade700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  side: BorderSide(color: onDark ? Colors.white : kBorderColor, width: kBorderWidth),
                  foregroundColor: onDark ? Colors.white : Colors.black,
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
            Text(label, style: GoogleFonts.chewy(fontSize: 12, color: Colors.black54)),
            Text(value, style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 15)),
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
        Text(value, style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
        const SizedBox(height: 2),
        Text(label, style: appBodyStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF888888))),
      ],
    );
  }
}
