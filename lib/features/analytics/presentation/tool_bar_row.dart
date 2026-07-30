import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/app_styles.dart';
import '../providers.dart';

/// A single tool's usage as a horizontal bar, scaled against [maxCount].
/// Shared between the full Pro "Top tools" list and the blurred teaser
/// shown on the free Projects screen.
class ToolBarRow extends StatelessWidget {
  const ToolBarRow({super.key, required this.tool, required this.maxCount});

  final ToolUsage tool;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : tool.count / maxCount;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            tool.tool,
            style: GoogleFonts.chewy(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  Container(
                    height: 14,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: kAccentColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text(
            '${tool.count}',
            textAlign: TextAlign.right,
            style: GoogleFonts.chewy(fontWeight: FontWeight.bold, fontSize: 14, color: kAccentColor),
          ),
        ),
      ],
    );
  }
}
