import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared look-and-feel constants matching the home screen's comic-panel style:
/// white background, black text/borders in the Chewy font, and a deep orange accent.
const kBorderColor = Colors.black;
const kBorderWidth = 2.0;
const kAccentColor = Colors.deepOrange;

TextStyle appHeadlineStyle({double fontSize = 56, Color color = kAccentColor}) {
  return GoogleFonts.sedgwickAveDisplay(fontSize: fontSize, height: 1.0, color: color);
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
