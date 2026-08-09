import 'package:flutter/material.dart';

import '../../../shared/app_icons.dart';
import '../../../shared/app_styles.dart';
import '../domain/league_region.dart';

/// Bottom sheet listing [leagueRegions]; returns the picked key, or null if
/// dismissed without picking. Shared by the league screen's first-time
/// prompt and the "change region" row in Edit Profile.
Future<String?> pickLeagueRegion(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _RegionPickerSheet(current: current),
  );
}

class _RegionPickerSheet extends StatelessWidget {
  const _RegionPickerSheet({required this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick your region', style: appBodyStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              "You'll compete in this region's weekly league.",
              style: appBodyStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedColor),
            ),
            const SizedBox(height: 16),
            for (final entry in leagueRegions.entries) ...[
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).pop(entry.key),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: entry.key == current ? kAccentTintColor : Colors.white,
                    border: Border.all(color: kHairlineColor, width: 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value,
                          style: appBodyStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (entry.key == current) const AppIcon(AppIcons.checkCircle, color: kAccentColor, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
