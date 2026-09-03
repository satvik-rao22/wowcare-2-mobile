import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';

/// A tinted row inside a card: a classroom's ratio, a classroom's shift.
///
/// Optionally led by a coloured bar, which is how a ratio row says at a
/// glance whether it is short before any of the words are read, and closed by
/// either a flag in ink or a pill.
class InnerRow extends StatelessWidget {
  const InnerRow({
    required this.title,
    required this.subtitle,
    required this.fill,
    required this.subtitleColor,
    this.line,
    this.barColor,
    this.flag,
    this.flagColor,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;

  final Color fill;
  final Color? line;
  final Color subtitleColor;

  /// The 8 by 30 bar at the head of a ratio row.
  final Color? barColor;

  /// A word at the end of the row: "+1 staff", "In Ratio".
  final String? flag;
  final Color? flagColor;

  /// A pill at the end instead of a flag: Filled, Open.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      padding: DashboardSizes.innerRowPad,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadii.innerR,
        border: line == null ? null : Border.all(color: line!),
      ),
      child: Row(
        spacing: DashboardSizes.innerRowGap,
        children: <Widget>[
          if (barColor != null)
            Container(
              width: DashboardSizes.ratioBarWidth,
              height: DashboardSizes.ratioBarHeight,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(
                  DashboardSizes.ratioBarRadius,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: DashboardTextStyles.innerRowTitle.copyWith(
                    color: c.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: DashboardTextStyles.innerRowSub.copyWith(
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          if (flag != null)
            Text(
              flag!,
              style: DashboardTextStyles.innerRowFlag.copyWith(
                color: flagColor ?? c.ink2,
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}
