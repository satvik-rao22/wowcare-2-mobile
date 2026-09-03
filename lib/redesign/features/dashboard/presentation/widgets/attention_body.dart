import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// The bottom half of an attention card, which is different for every kind.
///
/// Kept apart from `AttentionCard` so the chrome stays one widget: the card
/// knows how loud it is, and this knows what it is about.
class AttentionBody extends StatelessWidget {
  const AttentionBody({
    required this.kind,
    required this.summary,
    required this.onOpen,
    super.key,
  });

  final AttentionKind kind;
  final AttentionSummary summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return switch (kind) {
      AttentionKind.incidents => _headline(
        c,
        value: '${summary.pendingIncidents}',
        label: DashboardStrings.reports(summary.pendingIncidents),
        valueColor: c.dangerFg,
        action: DashboardStrings.review,
      ),
      AttentionKind.ratio => Row(
        spacing: DashboardSizes.attentionWellGap,
        children: <Widget>[
          for (final short in summary.ratioShortfalls.take(2))
            Expanded(
              child: _Tint(
                fill: c.dangerBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      short.classroomName,
                      style: DashboardTextStyles.innerRowSub.copyWith(
                        color: c.ink,
                      ),
                    ),
                    Text(
                      DashboardStrings.staffShort(
                        short.staffPresent,
                        short.staffNeeded,
                      ),
                      style: DashboardTextStyles.innerRowFlag.copyWith(
                        color: c.dangerFg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      AttentionKind.shifts => _shifts(c),
      AttentionKind.movements => Row(
        spacing: DashboardSizes.attentionWellGap,
        children: <Widget>[
          Expanded(
            child: _count(
              c,
              label: DashboardStrings.pending,
              value: summary.pendingMovements,
              fill: c.staffBg,
              ink: c.staffFg,
            ),
          ),
          Expanded(
            child: _count(
              c,
              label: DashboardStrings.overdue,
              value: summary.overdueMovements,
              fill: c.dangerBg,
              ink: c.dangerFg,
            ),
          ),
        ],
      ),
      AttentionKind.documents => _twoLines(
        c,
        first: DashboardStrings.expiredAndSoon(
          summary.expiredStudentDocuments,
          summary.expiringStudentDocuments,
        ),
        firstColor: summary.expiredStudentDocuments > 0
            ? c.dangerFg
            : c.staffFg,
        second: DashboardStrings.soon(summary.expiringStaffDocuments),
      ),
      AttentionKind.checkups => _twoLines(
        c,
        first: DashboardStrings.expiredAndSoon(
          summary.overdueStudentCheckups,
          summary.missingStudentCheckups,
        ),
        firstColor: c.dangerFg,
        second: DashboardStrings.soon(summary.overdueStaffCheckups),
      ),
      AttentionKind.billing => _billing(c),
    };
  }

  // --- The shapes -----------------------------------------------------------

  Widget _headline(
    Colourway c, {
    required String value,
    required String label,
    required Color valueColor,
    required String action,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: DashboardSizes.attentionHeadlineGap,
          children: <Widget>[
            Text(
              value,
              style: AppTextStyles.headlineCount.copyWith(color: valueColor),
            ),
            Text(
              label,
              style: DashboardTextStyles.attentionHeadlineLabel.copyWith(
                color: c.ink3,
              ),
            ),
          ],
        ),
      ),
      _ActionPill(
        label: action,
        fill: c.pink,
        rim: c.pinkRim,
        ink: c.onPink,
        onTap: onOpen,
      ),
    ],
  );

  Widget _shifts(Colourway c) {
    final shift = summary.openShift;
    if (shift == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                DashboardStrings.shiftWindow(
                  shift.classroomName,
                  _window(shift),
                ),
                style: DashboardTextStyles.innerRowTitle.copyWith(color: c.ink),
              ),
              Text(
                DashboardStrings.shiftNeeds(
                  shift.staffNeeded,
                  shift.staffScheduled,
                ),
                style: DashboardTextStyles.innerRowSub.copyWith(
                  color: c.staffFg,
                ),
              ),
            ],
          ),
        ),
        _ActionPill(
          label: DashboardStrings.scheduling,
          fill: c.staff,
          rim: c.staffFg,
          ink: c.ink,
          onTap: onOpen,
        ),
      ],
    );
  }

  Widget _count(
    Colourway c, {
    required String label,
    required int value,
    required Color fill,
    required Color ink,
  }) => _Tint(
    fill: fill,
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: DashboardTextStyles.innerRowSub.copyWith(color: ink),
          ),
        ),
        Text(
          '$value',
          style: DashboardTextStyles.attentionTileValue.copyWith(color: ink),
        ),
      ],
    ),
  );

  Widget _twoLines(
    Colourway c, {
    required String first,
    required Color firstColor,
    required String second,
  }) => Column(
    spacing: DashboardSizes.attentionRowGap,
    children: <Widget>[
      _Line(
        label: AppStrings.students,
        value: first,
        valueColor: firstColor,
      ),
      _Line(
        label: AppStrings.staff,
        value: second,
        valueColor: c.staffFg,
      ),
    ],
  );

  Widget _billing(Colourway c) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: DashboardSizes.attentionHeadlineGap,
          children: <Widget>[
            Flexible(
              child: Text(
                _money(summary.outstandingAmount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DashboardTextStyles.attentionMoney.copyWith(
                  color: c.onImpact,
                ),
              ),
            ),
            Text(
              DashboardStrings.percent(summary.outstandingPercent),
              style: DashboardTextStyles.attentionHeadlineLabel.copyWith(
                color: c.staff,
              ),
            ),
          ],
        ),
      ),
      _ActionPill(
        label: DashboardStrings.openBilling,
        fill: c.card,
        rim: c.keyRim,
        ink: c.ink,
        onTap: onOpen,
      ),
    ],
  );

  static String _window(OpenShiftGap shift) =>
      '${_clock(shift.start.hour, shift.start.minute)} – '
      '${_clock(shift.end.hour, shift.end.minute)}';

  static String _clock(int hour, int minute) =>
      '$hour:${minute.toString().padLeft(2, '0')}';

  /// Whole dollars, grouped. Currency formatting proper lands with M10.
  static String _money(double amount) {
    final digits = amount.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '\$$buffer';
  }
}

/// A tinted well inside an attention card.
class _Tint extends StatelessWidget {
  const _Tint({required this.fill, required this.child});

  final Color fill;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: DashboardSizes.attentionWellPad,
    decoration: BoxDecoration(color: fill, borderRadius: AppRadii.innerR),
    child: child,
  );
}

/// One "Students · 2 expired · 6 soon" line.
class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: DashboardTextStyles.innerRowFlag.copyWith(color: c.ink),
          ),
        ),
        Text(
          value,
          style: DashboardTextStyles.innerRowFlag.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

/// The one key on an attention card: a pill on a 3px rim.
class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.fill,
    required this.rim,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final Color rim;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Pressable.surface(
      onTap: onTap,
      child: Container(
        padding: DashboardSizes.attentionActionPad,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: AppRadii.pillR,
          boxShadow: <BoxShadow>[
            BoxShadow(color: rim, offset: const Offset(0, 3)),
          ],
        ),
        child: Text(
          label,
          style: DashboardTextStyles.attentionAction.copyWith(color: ink),
        ),
      ),
    ),
  );
}
