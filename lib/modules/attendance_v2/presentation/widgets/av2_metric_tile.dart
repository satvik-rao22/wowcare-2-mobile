import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';

/// A compact label-over-value tile on a muted surface. Used for the
/// Attended / Absent / Avg trio in the hero card.
class Av2MetricTile extends StatelessWidget {
  const Av2MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: AppSurfaces.well(radius: Av2Spacing.radiusSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Av2Text.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: value,
              style: Av2Text.metricValue,
              children: suffix == null
                  ? null
                  : [TextSpan(text: ' $suffix', style: Av2Text.caption)],
            ),
          ),
        ],
      ),
    );
  }
}
