import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';

/// A status pill with a dot in front of it, the way a card's title row wears
/// one: Signed In, In Ratio, Filled.
///
/// `StatusPill` is the list-row form and carries no dot; this is the card
/// form, and the dot is what makes it readable beside a heading.
class DotPill extends StatelessWidget {
  const DotPill({
    required this.label,
    required this.fill,
    required this.ink,
    this.dot,
    super.key,
  });

  final String label;
  final Color fill;
  final Color ink;

  /// Defaults to [ink], which is what most of the frames draw.
  final Color? dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: DashboardSizes.statusPillPad,
    decoration: BoxDecoration(color: fill, borderRadius: AppRadii.pillR),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: DashboardSizes.statusPillDotGap,
      children: <Widget>[
        Container(
          width: DashboardSizes.statusPillDot,
          height: DashboardSizes.statusPillDot,
          decoration: BoxDecoration(
            color: dot ?? ink,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          label,
          style: DashboardTextStyles.statusPillText.copyWith(color: ink),
        ),
      ],
    ),
  );
}
