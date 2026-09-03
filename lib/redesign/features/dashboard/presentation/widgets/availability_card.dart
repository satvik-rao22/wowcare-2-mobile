import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';

/// The two-up row under the shifts card (3A2): how full the school is, and
/// how many classroom moves are waiting on an Admin.
///
/// Two facts on one card rather than two cards, because neither is worth a
/// card of its own and side by side they read as one sentence about capacity.
class AvailabilityCard extends StatelessWidget {
  const AvailabilityCard({
    required this.placesFilled,
    required this.capacity,
    required this.movesToApprove,
    required this.onOpenAvailability,
    required this.onOpenMovements,
    super.key,
  });

  final int placesFilled;
  final int capacity;
  final int movesToApprove;
  final VoidCallback onOpenAvailability;
  final VoidCallback onOpenMovements;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Row(
        spacing: DashboardSizes.summaryGap,
        children: <Widget>[
          Expanded(
            child: _Fact(
              value: '$placesFilled',
              label: DashboardStrings.placesFilled(capacity),
              valueColor: c.student,
              onTap: onOpenAvailability,
            ),
          ),
          Container(
            width: AppSizes.hairline,
            height: DashboardSizes.summaryDividerHeight,
            color: c.divider,
          ),
          Expanded(
            child: _Fact(
              value: '$movesToApprove',
              label: DashboardStrings.movesToApprove,
              valueColor: c.staffFg,
              onTap: onOpenMovements,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.onTap,
  });

  final String value;
  final String label;
  final Color valueColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Colourway c = context.colours;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: DashboardSizes.summaryNumberGap,
        children: <Widget>[
          Text(
            value,
            style: DashboardTextStyles.summaryNumber.copyWith(
              color: valueColor,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: DashboardTextStyles.summaryLabel.copyWith(color: c.ink3),
            ),
          ),
        ],
      ),
    );
  }
}
