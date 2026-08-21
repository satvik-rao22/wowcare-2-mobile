import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';

/// Shared visual language for every billing card, inherited from
/// [staff_card.dart] (`lib/presentation/features/staff/widgets/staff_card.dart`).
///
/// All billing cards use the same white, rounded, [AppColors.cardBorderColor]
/// bordered, tap-to-expand container, the same `#573353` text colour and the
/// same Manrope font sizes/weights so they match the staff card exactly.
const Color kBillingCardTextColor = Color(0xff573353);
const Color kBillingCarddividerColor = Color(0xFFE9ECEF);

/// Text styles lifted verbatim from the staff card.
class BillingCardText {
  BillingCardText._();

  /// Header name/title — Manrope 14 (16 on tablet), w500.
  static TextStyle name(bool isTablet) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: isTablet ? 16 : 14,
    fontWeight: FontWeight.w500,
    color: kBillingCardTextColor,
    height: 19 / 14,
  );

  /// Detail-row label — Manrope 13, w400.
  static const TextStyle label = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: kBillingCardTextColor,
    height: 16 / 13,
  );

  /// Detail-row value — Manrope 14, w500.
  static const TextStyle value = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: kBillingCardTextColor,
    height: 19 / 14,
  );

  /// Small sub-note shown under a value — Manrope 10, w500.
  static const TextStyle note = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: kBillingCardTextColor,
    height: 14 / 10,
  );
}

/// Staff-card-style expandable container used by every billing card.
///
/// The [header] is shown in both collapsed and expanded states. When collapsed,
/// an optional [collapsedPrefix] (e.g. a selection checkbox) is shown before the
/// [leading] avatar. Tapping the card toggles [expandedChildren].
class StaffStyleCard extends StatefulWidget {
  const StaffStyleCard({
    super.key,
    this.collapsedPrefix,
    this.leading,
    required this.header,
    this.expandedChildren = const <Widget>[],
    this.initiallyExpanded = false,
    this.onLongPress,
    this.onExpandChanged,
    this.isExpanded,
  });

  /// Shown only while collapsed, before [leading] (e.g. a checkbox).
  final Widget? collapsedPrefix;

  /// Leading avatar — pass a `DocumentImageWidget` for person cards.
  final Widget? leading;

  /// Header content placed in the `Expanded` slot of the header row. Typically a
  /// `Row(mainAxisAlignment: spaceBetween, ...)` for a title/trailing layout.
  final Widget header;

  /// Rows + action buttons revealed when expanded.
  final List<Widget> expandedChildren;

  final bool initiallyExpanded;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onExpandChanged;

  /// Optional externally-controlled expansion. When null, the card manages its
  /// own state.
  final bool? isExpanded;

  @override
  State<StaffStyleCard> createState() => _StaffStyleCardState();
}

class _StaffStyleCardState extends State<StaffStyleCard> {
  late bool _isExpanded = widget.initiallyExpanded;

  bool get _expanded => widget.isExpanded ?? _isExpanded;

  void _toggle() {
    final next = !_expanded;
    if (widget.isExpanded == null) {
      setState(() => _isExpanded = next);
    }
    widget.onExpandChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderColor, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: _toggle,
                onLongPress: widget.onLongPress,
                child: Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 16,
                        vertical: 8,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!_expanded && widget.collapsedPrefix != null) ...[
                            widget.collapsedPrefix!,
                            SizedBox(width: isTablet ? 16 : 9),
                          ],
                          if (widget.leading != null) ...[
                            widget.leading!,
                            SizedBox(width: isTablet ? 16 : 9),
                          ],
                          Expanded(child: widget.header),
                        ],
                      ),
                    ),
                    if (_expanded) ...[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: kBillingCarddividerColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.expandedChildren,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A label/value detail row in the expanded body, styled like the staff card
/// (label left in [BillingCardText.label], value right in [BillingCardText.value]).
class StaffCardDetailRow extends StatelessWidget {
  const StaffCardDetailRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.note,
    this.valueColor,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final String? note;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BillingCardText.label),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (valueWidget != null)
                valueWidget!
              else
                Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  style: valueColor != null
                      ? BillingCardText.value.copyWith(color: valueColor)
                      : BillingCardText.value,
                ),
              if (note != null && note!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  note!,
                  textAlign: TextAlign.right,
                  style: BillingCardText.note,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The staff card's bottom action row: an outlined secondary button (e.g.
/// Delete) next to a gradient-filled primary button (e.g. Edit).
class StaffCardActions extends StatelessWidget {
  const StaffCardActions({
    super.key,
    this.secondaryLabel,
    this.onSecondary,
    required this.primaryLabel,
    this.onPrimary,
  });

  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String primaryLabel;
  final VoidCallback? onPrimary;

  static const Color _accent = Color(0xFF6C7FD8);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (secondaryLabel != null) ...[
          Expanded(
            child: SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  secondaryLabel!,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                    height: 16 / 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.buildPrimaryGradient(),
            ),
            child: TextButton(
              onPressed: onPrimary,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  height: 16 / 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
