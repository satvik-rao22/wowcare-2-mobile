import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// Shared visual language for every billing card, inherited from
/// [staff_card.dart] (`lib/presentation/features/staff/widgets/staff_card.dart`).
///
/// All billing cards use the same white, rounded, [AppColors.cardBorderColor]
/// bordered, tap-to-expand container, the same `#573353` text colour and the
/// same Manrope font sizes/weights so they match the staff card exactly.
const Color kBillingCardTextColor = AppColors.billingTextColor;
const Color kBillingCardDividerColor = AppColors.billingDividerLight;

/// Text styles lifted verbatim from the staff card.
class BillingCardText {
  BillingCardText._();

  /// Header name/title — Manrope 14 (16 on tablet), w500.
  static TextStyle name(bool isTablet) => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: isTablet ? 16 : 14,
    fontWeight: FontWeight.w500,
    color: kBillingCardTextColor,
    height: 19 / 14,
  );

  /// Detail-row label — Manrope 13, w400.
  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: kBillingCardTextColor,
    height: 16 / 13,
  );

  /// Detail-row value — Manrope 14, w500.
  static const TextStyle value = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: kBillingCardTextColor,
    height: 19 / 14,
  );

  /// Small sub-note shown under a value — Manrope 10, w500.
  static const TextStyle note = TextStyle(
    fontFamily: AppFonts.body,
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
  late final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(
    widget.initiallyExpanded,
  );

  @override
  void dispose() {
    _isExpanded.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !(widget.isExpanded ?? _isExpanded.value);
    if (widget.isExpanded == null) {
      _isExpanded.value = next;
    }
    widget.onExpandChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isExpanded,
          builder: (context, internalExpanded, _) {
            final expanded = widget.isExpanded ?? internalExpanded;
            return IntrinsicHeight(
              child: Container(
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: AppColors.billingCardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cardBorderColor,
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: AppColors.transparentColor,
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
                              if (!expanded &&
                                  widget.collapsedPrefix != null) ...[
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
                        if (expanded) ...[
                          const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: kBillingCardDividerColor,
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

/// Full-width gradient-filled primary action button (e.g. View, Edit),
/// shared by [LedgerCard] and [DiscountCard], whose View / Edit-or-Reactivate
/// / Deactivate-or-Delete button arrangement varies per row and doesn't fit
/// [StaffCardActions]'s fixed outline+primary pair.
class FilledActionButton extends StatelessWidget {
  const FilledActionButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: SkeuKeyBox(
        variant: KeyVariant.primary,
        radius: AppRadius.sm,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.body,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.billingCardOnColorText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width outlined secondary action button (e.g. Delete, Deactivate) —
/// the counterpart to [FilledActionButton].
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  static const Color _accent = AppColors.billingCardAccent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _accent,
          ),
        ),
      ),
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

  static const Color _accent = AppColors.billingCardAccent;

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
                    fontFamily: AppFonts.body,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
          child: SkeuKeyBox(
            variant: KeyVariant.primary,
            radius: 8,
            height: 40,
            child: TextButton(
              onPressed: onPrimary,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                primaryLabel,
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.billingCardOnColorText,
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
