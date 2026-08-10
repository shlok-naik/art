import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_styles.dart';

/// The redesign's hand-picked outline icon set — 1.8 stroke, round
/// joins/caps, 24x24 viewBox, exactly as specified in the design handoff.
/// Each entry is the inner SVG markup with `{{c}}`/`{{w}}` placeholders for
/// color and stroke width, resolved by [AppIcon] at build time.
///
/// Material icons should not be mixed into redesigned screens — if a needed
/// glyph is missing here, add it in the same style rather than falling back
/// to `Icons.*`.
abstract final class AppIcons {
  static const home =
      '<path d="M4 11l8-7 8 7v9a1 1 0 0 1-1 1h-4v-6H9v6H5a1 1 0 0 1-1-1v-9z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const feed =
      '<rect x="4" y="4" width="16" height="16" rx="2" stroke="{{c}}" stroke-width="{{w}}"/><line x1="4" y1="9" x2="20" y2="9" stroke="{{c}}" stroke-width="{{w}}"/>';
  static const followed =
      '<circle cx="8" cy="9" r="3" stroke="{{c}}" stroke-width="{{w}}"/><circle cx="16" cy="9" r="3" stroke="{{c}}" stroke-width="{{w}}"/><path d="M2 20c0-3 3-5 6-5s6 2 6 5" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><path d="M12 20c0-2.5 2.2-4.3 4.5-4.3s4.5 1.8 4.5 4.3" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const profile =
      '<circle cx="12" cy="8" r="4" stroke="{{c}}" stroke-width="{{w}}"/><path d="M4 20c0-4.4 3.6-7 8-7s8 2.6 8 7" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const back =
      '<path d="M15 4l-8 8 8 8" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/>';
  static const chevronRight =
      '<path d="M9 4l8 8-8 8" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/>';
  static const globe =
      '<circle cx="12" cy="12" r="9" stroke="{{c}}" stroke-width="{{w}}"/><path d="M3 12h18M12 3c2.5 2.6 2.5 15 0 18M12 3c-2.5 2.6-2.5 15 0 18" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const search =
      '<circle cx="11" cy="11" r="7" stroke="{{c}}" stroke-width="{{w}}"/><line x1="21" y1="21" x2="16.65" y2="16.65" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const bell =
      '<path d="M12 3C8.7 3 6 5.7 6 9v4.5L4 17h16l-2-3.5V9c0-3.3-2.7-6-6-6z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/><path d="M9.5 20a2.5 2.5 0 0 0 5 0" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const heart =
      '<path d="M12 20.2s-7.6-4.6-9.6-9.1C1 7.6 3 4.5 6.2 4.2c2-.2 3.7 1 4.8 2.7 1.1-1.7 2.8-2.9 4.8-2.7 3.2.3 5.2 3.4 3.8 6.9-2 4.5-9.6 9.1-9.6 9.1z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const heartFilled =
      '<path d="M12 20.2s-7.6-4.6-9.6-9.1C1 7.6 3 4.5 6.2 4.2c2-.2 3.7 1 4.8 2.7 1.1-1.7 2.8-2.9 4.8-2.7 3.2.3 5.2 3.4 3.8 6.9-2 4.5-9.6 9.1-9.6 9.1z" fill="{{c}}"/>';
  static const comment =
      '<path d="M4 4h16v12H9l-5 4V4z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const share =
      '<path d="M4 12l16-8-6 16-3-7-7-1z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const crown =
      '<path d="M3 8l4 4 5-7 5 7 4-4-2 11H5L3 8z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const flame =
      '<path d="M12 22c4-1 6-4 6-8 0-2.5-1.5-4-2.5-5.5C15 10 14 12 13 11c-1-1-.5-3.5-2-5.5C9 8 7 10 7 14c0 4 2 7 6 8z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const eye =
      '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/><circle cx="12" cy="12" r="3" stroke="{{c}}" stroke-width="{{w}}"/>';
  static const play = '<path d="M6 4l14 8-14 8V4z" fill="{{c}}"/>';
  static const trophy =
      '<path d="M8 4h8v4a4 4 0 01-8 0V4z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/><path d="M8 5H5a2 2 0 002 4M16 5h3a2 2 0 01-2 4" stroke="{{c}}" stroke-width="{{w}}"/><path d="M12 12v4M9 20h6M10 16h4v4h-4z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const barChart =
      '<path d="M4 20V10M10 20V4M16 20v-7M22 20H2" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/>';
  static const image =
      '<rect x="3" y="4" width="18" height="16" rx="2" stroke="{{c}}" stroke-width="{{w}}"/><circle cx="8.5" cy="9.5" r="1.5" stroke="{{c}}" stroke-width="{{w}}"/><path d="M3 17l5-5 4 4 4-5 5 6" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const folder =
      '<path d="M3 7a2 2 0 012-2h4l2 2h8a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V7z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const pencil =
      '<path d="M4 20h4l10-10-4-4L4 16v4z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const clock =
      '<circle cx="12" cy="12" r="9" stroke="{{c}}" stroke-width="{{w}}"/><path d="M12 7v5l3.5 2" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const lock =
      '<rect x="5" y="11" width="14" height="9" rx="2" stroke="{{c}}" stroke-width="{{w}}"/><path d="M8 11V8a4 4 0 018 0v3" stroke="{{c}}" stroke-width="{{w}}"/>';
  static const plus =
      '<line x1="12" y1="5" x2="12" y2="19" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><line x1="5" y1="12" x2="19" y2="12" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const checkCircle =
      '<circle cx="12" cy="12" r="9" stroke="{{c}}" stroke-width="{{w}}"/><path d="M8 12l3 3 5-6" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/>';
  static const x =
      '<line x1="6" y1="6" x2="18" y2="18" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><line x1="18" y1="6" x2="6" y2="18" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  // Reaction glyphs — line-drawn stand-ins for the old color emoji on the
  // post detail breakdown. Same 24x24 / 1.8-stroke language as the rest.
  static const thumbDown =
      '<path d="M17 3h2a2 2 0 012 2v6a2 2 0 01-2 2h-2V3z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/><path d="M17 13l-3.5 7a2.5 2.5 0 01-3.5-2.3V14H5.6a2 2 0 01-2-2.4l1.2-6A2 2 0 016.8 4H17v9z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const smile =
      '<circle cx="12" cy="12" r="9" stroke="{{c}}" stroke-width="{{w}}"/><path d="M8 14c1 1.6 2.4 2.4 4 2.4s3-.8 4-2.4" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><circle cx="9" cy="10" r="1" fill="{{c}}"/><circle cx="15" cy="10" r="1" fill="{{c}}"/>';
  static const surprise =
      '<circle cx="12" cy="12" r="9" stroke="{{c}}" stroke-width="{{w}}"/><ellipse cx="12" cy="15" rx="2.2" ry="2.6" stroke="{{c}}" stroke-width="{{w}}"/><circle cx="9" cy="10" r="1" fill="{{c}}"/><circle cx="15" cy="10" r="1" fill="{{c}}"/>';
  static const frown =
      '<circle cx="12" cy="12" r="9" stroke="{{c}}" stroke-width="{{w}}"/><path d="M8 16.4c1-1.6 2.4-2.4 4-2.4s3 .8 4 2.4" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><circle cx="9" cy="10" r="1" fill="{{c}}"/><circle cx="15" cy="10" r="1" fill="{{c}}"/>';
  static const angry =
      '<circle cx="12" cy="12" r="9" stroke="{{c}}" stroke-width="{{w}}"/><path d="M8 16.4c1-1.6 2.4-2.4 4-2.4s3 .8 4 2.4" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><path d="M7.4 8.4l2.6 1.4M16.6 8.4L14 9.8" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const camera =
      '<path d="M3 8a2 2 0 012-2h2.5l1.5-2h6l1.5 2H21a0 0 0 010 0 2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V8z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/><circle cx="12" cy="13" r="4" stroke="{{c}}" stroke-width="{{w}}"/>';
  static const upload =
      '<path d="M12 16V4M8 8l4-4 4 4" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/><path d="M4 15v3a2 2 0 002 2h12a2 2 0 002-2v-3" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const pause =
      '<rect x="6" y="4" width="4" height="16" rx="1" stroke="{{c}}" stroke-width="{{w}}"/><rect x="14" y="4" width="4" height="16" rx="1" stroke="{{c}}" stroke-width="{{w}}"/>';
  static const stop = '<rect x="5" y="5" width="14" height="14" rx="2" fill="{{c}}"/>';
  static const replay =
      '<path d="M4 12a8 8 0 108-8" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><path d="M12 1l-3.5 3L12 7" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/>';
  static const check =
      '<path d="M5 12.5l4.5 4.5L19 7" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/>';
  static const pin =
      '<path d="M9 3h6l-1 6 4 3v2h-5.5V21h-1V14H6v-2l4-3-1-6z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const filter =
      '<path d="M4 6h16M7 12h10M10 18h4" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const sort =
      '<path d="M7 4v16M7 20l-3-3M7 20l3-3M17 20V4M17 4l-3 3M17 4l3 3" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/>';
  static const gauge =
      '<path d="M4 18a8 8 0 1116 0" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><path d="M12 18l4-5" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const brain =
      '<path d="M9 4.5A2.5 2.5 0 006.5 7 2.5 2.5 0 005 9.5c0 1 .6 1.9 1.4 2.3A2.5 2.5 0 007 16.5c0 1.4 1.1 2.5 2.5 2.5S12 17.9 12 16.5V5.8A2.5 2.5 0 009 4.5z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/><path d="M15 4.5A2.5 2.5 0 0117.5 7 2.5 2.5 0 0119 9.5c0 1-.6 1.9-1.4 2.3A2.5 2.5 0 0117 16.5c0 1.4-1.1 2.5-2.5 2.5S12 17.9 12 16.5V5.8A2.5 2.5 0 0115 4.5z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const pieChart =
      '<circle cx="12" cy="12" r="9" stroke="{{c}}" stroke-width="{{w}}"/><path d="M12 3v9h9" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const brush =
      '<path d="M14 4l6 6-7 7H9v-4l5-9z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/><path d="M9 17c0 2-1.5 3.5-4 3.5 1-1 1-2 1-3.5h3z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const personAdd =
      '<circle cx="9" cy="8" r="4" stroke="{{c}}" stroke-width="{{w}}"/><path d="M2 20c0-4 3.2-6.5 7-6.5s7 2.5 7 6.5" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><path d="M18 8v6M15 11h6" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/>';
  static const bulb =
      '<path d="M9 18h6M10 21h4" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><path d="M12 3a6 6 0 00-3.5 10.9c.5.4.8 1 .8 1.6V16h5.4v-.5c0-.6.3-1.2.8-1.6A6 6 0 0012 3z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const trendUp =
      '<path d="M3 17l6-6 4 4 8-8" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/><path d="M15 7h6v6" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round" stroke-linejoin="round"/>';
  static const hourglass =
      '<path d="M7 3h10M7 21h10" stroke="{{c}}" stroke-width="{{w}}" stroke-linecap="round"/><path d="M8 3v3.5c0 2 4 3.6 4 5.5 0-1.9 4-3.5 4-5.5V3M8 21v-3.5c0-2 4-3.6 4-5.5 0 1.9 4 3.5 4 5.5V21" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const send =
      '<path d="M4 12l16-8-6 16-3-7-7-1z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const more =
      '<circle cx="5" cy="12" r="1.4" fill="{{c}}"/><circle cx="12" cy="12" r="1.4" fill="{{c}}"/><circle cx="19" cy="12" r="1.4" fill="{{c}}"/>';
  static const star =
      '<path d="M12 3.6l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.3-4.1 5.9-.9L12 3.6z" stroke="{{c}}" stroke-width="{{w}}" stroke-linejoin="round"/>';
  static const grid =
      '<rect x="3" y="3" width="8" height="8" rx="1.5" stroke="{{c}}" stroke-width="{{w}}"/><rect x="13" y="3" width="8" height="8" rx="1.5" stroke="{{c}}" stroke-width="{{w}}"/><rect x="3" y="13" width="8" height="8" rx="1.5" stroke="{{c}}" stroke-width="{{w}}"/><rect x="13" y="13" width="8" height="8" rx="1.5" stroke="{{c}}" stroke-width="{{w}}"/>';
}

/// Renders one [AppIcons] entry at [size] in [color]. Stroke width stays
/// 1.8 by design regardless of size (the handoff's icons are all drawn at
/// that weight); pass [strokeWidth] only where the design calls for 2 (the
/// navy app-bar icons).
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color = kInkColor,
    this.strokeWidth = 1.8,
  });

  final String icon;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    final svg =
        '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">'
        '${icon.replaceAll('{{c}}', hex).replaceAll('{{w}}', '$strokeWidth')}'
        '</svg>';
    return SvgPicture.string(svg, width: size, height: size);
  }
}

/// Colored initials avatar replacing the old icon-placeholder circles. The
/// per-artist color is picked deterministically from the handle so the same
/// artist always gets the same color everywhere.
class AppInitialsAvatar extends StatelessWidget {
  const AppInitialsAvatar({
    super.key,
    required this.name,
    this.size = 42,
    this.color,
    this.imageUrl,
  });

  final String name;
  final double size;

  /// Overrides the hash-picked background (e.g. the profile screen's avatar
  /// is always navy).
  final Color? color;

  /// When set, shows this profile picture instead of the initials — the
  /// initials remain the fallback while it loads or if it fails to load.
  final String? imageUrl;

  static const _palette = [kNavyColor, kAccentColor, kMutedColor];

  static String initialsOf(String name) {
    final cleaned = name.replaceAll(RegExp(r'[@_]'), ' ').trim();
    if (cleaned.isEmpty) return '?';
    final parts = cleaned.split(RegExp(r'[\s.]+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final background = color ?? _palette[name.hashCode.abs() % _palette.length];
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      alignment: Alignment.center,
      child: Text(
        initialsOf(name),
        style: appBodyStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }
}

/// Pushed-screen header used by the redesigned League / Analytics / My Posts
/// / Projects screens in place of a Material AppBar: back chevron + 18/600
/// ink title on white, a 1px hairline underneath, optional trailing widget
/// pinned right. White rather than navy so the system status-bar clock and
/// battery glyphs stay legible above it.
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kHairlineColor, width: 1)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: AppIcon(AppIcons.back, color: kInkColor, strokeWidth: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: appBodyStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kInkColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// The museum treatment applied to every user photo in the app: a navy mat
/// with a gold hairline sitting just inside it, both sharing one corner
/// radius family (inner [radius], outer `radius + 5`).
class MuseumFrame extends StatelessWidget {
  const MuseumFrame({super.key, required this.child, this.radius = 6, this.matWidth = 5});

  final Widget child;

  /// Corner radius of the photo itself. The navy mat is drawn at
  /// `radius + matWidth` so the two curves stay concentric.
  final double radius;

  /// Thickness of the navy mat around the gold hairline.
  final double matWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(matWidth),
      decoration: BoxDecoration(
        color: kNavyColor,
        borderRadius: BorderRadius.circular(radius + matWidth),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: kGoldColor, width: 1.5),
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Numbered rank badge for league standings — a gold (1st) / silver (2nd) /
/// surface (everything else) circle with the position in navy, replacing the
/// medal emoji.
class AppRankBadge extends StatelessWidget {
  const AppRankBadge({super.key, required this.rank, this.size = 26});

  final int rank;
  final double size;

  static const _silver = Color(0xFFC9CDD6);
  static const _bronze = Color(0xFFD8A47F);

  @override
  Widget build(BuildContext context) {
    final fill = switch (rank) {
      1 => kGoldColor,
      2 => _silver,
      3 => _bronze,
      _ => kSurfaceColor,
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
      child: Text(
        '$rank',
        style: appBodyStyle(
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          color: rank <= 3 ? kNavyColor : kMutedColor,
        ),
      ),
    );
  }
}

/// A star rating readout — the plain ★ glyph (U+2605) plus its count, in
/// gold. Used anywhere a rating total is shown; never the color emoji.
class AppStarCount extends StatelessWidget {
  const AppStarCount({super.key, required this.label, this.fontSize = 13, this.color = kGoldColor});

  final String label;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '★ $label',
      style: appBodyStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: color),
    );
  }
}
