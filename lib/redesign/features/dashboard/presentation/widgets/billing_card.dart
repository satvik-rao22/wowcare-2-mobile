import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// The Admin's money card (3A2), and the one impact surface on the screen.
///
/// Navy is the app's way of saying "this outranks the rest", and there is
/// exactly one of it per screen. Sun carries the two figures that are still
/// owed; warm white carries the two that are settled.
class BillingCard extends StatelessWidget {
  const BillingCard({
    required this.summary,
    required this.onChangeRange,
    required this.onOpenUnpaid,
    super.key,
  });

  final BillingSummary summary;
  final VoidCallback onChangeRange;
  final VoidCallback onOpenUnpaid;

  /// How far the warm white is pulled back for a surface on the navy card.
  static const double _glassAlpha = .1;
  static const double _keyAlpha = .12;
  static const double _labelAlpha = .6;
  static const double _chevronAlpha = .7;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.impact(c),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.timeCardGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DashboardStrings.billing,
                  style: AppTextStyles.cardTitle.copyWith(color: c.onImpact),
                ),
              ),
              _RangeKey(label: summary.rangeLabel, onTap: onChangeRange),
            ],
          ),
          Row(
            spacing: DashboardSizes.billingColumnGap,
            children: <Widget>[
              Expanded(
                child: _Figure(
                  value: summary.invoiced,
                  label: DashboardStrings.invoiced,
                  color: c.onImpact,
                ),
              ),
              Expanded(
                child: _Figure(
                  value: summary.netPaid,
                  label: DashboardStrings.netPaid,
                  color: c.success,
                ),
              ),
              Expanded(
                child: _Figure(
                  value: summary.inProcess,
                  label: DashboardStrings.inProcess,
                  color: c.onImpact,
                ),
              ),
              Expanded(
                child: _Figure(
                  value: summary.outstanding,
                  label: DashboardStrings.outstanding,
                  color: c.staff,
                ),
              ),
            ],
          ),
          _unpaid(c),
        ],
      ),
    );
  }

  Widget _unpaid(Colourway c) => Semantics(
    button: true,
    label: DashboardStrings.allUnpaidToDate,
    child: Pressable.surface(
      onTap: onOpenUnpaid,
      child: Container(
        padding: DashboardSizes.unpaidRowPad,
        decoration: BoxDecoration(
          color: c.onImpact.withValues(alpha: _glassAlpha),
          borderRadius: AppRadii.innerR,
        ),
        child: Row(
          spacing: DashboardSizes.unpaidRowGap,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    DashboardStrings.allUnpaidToDate,
                    style: DashboardTextStyles.unpaidTitle.copyWith(
                      color: c.onImpact,
                    ),
                  ),
                  Text(
                    DashboardStrings.allUnpaidSub,
                    style: DashboardTextStyles.unpaidSub.copyWith(
                      color: c.onImpact.withValues(alpha: _labelAlpha),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              money(summary.allUnpaid, compact: false),
              style: DashboardTextStyles.unpaidValue.copyWith(color: c.staff),
            ),
            Icon(
              AppIcons.chevronRight,
              size: DashboardSizes.unpaidChevron,
              color: c.onImpact.withValues(alpha: _chevronAlpha),
            ),
          ],
        ),
      ),
    ),
  );

  /// Money, the way the frames write it: `$94.2k` in a column of four,
  /// `$12,480` where there is room for the whole number.
  static String money(double amount, {bool compact = true}) {
    if (compact && amount >= 1000) {
      final thousands = amount / 1000;
      return '\$${thousands.toStringAsFixed(1)}k';
    }
    final digits = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '\$$buffer';
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.value,
    required this.label,
    required this.color,
  });

  final double value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            BillingCard.money(value),
            style: DashboardTextStyles.billingAmount.copyWith(color: color),
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DashboardTextStyles.billingLabel.copyWith(
            color: c.onImpactSoft,
          ),
        ),
      ],
    );
  }
}

/// The date range the card is showing, which opens a picker.
class _RangeKey extends StatelessWidget {
  const _RangeKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: DashboardStrings.billingRangeTitle,
      child: Pressable.surface(
        onTap: onTap,
        child: Container(
          padding: DashboardSizes.rangeKeyPad,
          decoration: BoxDecoration(
            color: c.onImpact.withValues(alpha: BillingCard._keyAlpha),
            borderRadius: AppRadii.pillR,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: DashboardSizes.rangeKeyGap,
            children: <Widget>[
              Text(
                label,
                style: DashboardTextStyles.rangeKeyText.copyWith(
                  color: c.staff,
                ),
              ),
              Icon(
                AppIcons.chevronDown,
                size: DashboardSizes.rangeKeyCaret,
                color: c.staff,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
