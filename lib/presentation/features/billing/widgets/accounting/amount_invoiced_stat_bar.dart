import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/cubit/bool_toggle_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';

class AmountInvoicedStatBar extends StatefulWidget {
  /// Actual amounts straight from the billing overview API. The label values
  /// are shown verbatim (no clamping) so negatives and >100% shares display
  /// correctly; percentages are derived as `amount / totalAmount` and only
  /// clamped for the progress-bar segment widths.
  final double totalAmount;
  final double netPaidAmount;

  /// Gross paid (before refunds), shown as the "Paid" item in the expanded view.
  final double paidAmount;
  final double inProcessAmount;
  final double outstandingAmount;
  final double refundedAmount;
  final String title;

  const AmountInvoicedStatBar({
    super.key,
    required this.totalAmount,
    required this.netPaidAmount,
    required this.paidAmount,
    required this.inProcessAmount,
    required this.outstandingAmount,
    this.refundedAmount = 0,
    this.title = 'Amount Invoiced',
  });

  @override
  State<AmountInvoicedStatBar> createState() => _AmountInvoicedStatBarState();
}

class _AmountInvoicedStatBarState extends State<AmountInvoicedStatBar> {
  late final BoolToggleCubit _cubit = BoolToggleCubit();
  bool get _isExpanded => _cubit.state;

  void _toggleExpanded() => _cubit.toggle();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoolToggleCubit>.value(
      value: _cubit,
      child: BlocBuilder<BoolToggleCubit, bool>(
        builder: (context, _) {
          final numberFormat = NumberFormat('#,##0');
          String formatAmount(double value) {
            final sign = value < 0 ? '-' : '';
            return '$sign\$${numberFormat.format(value.abs())}';
          }

          // Share of the invoiced amount; shown verbatim in labels.
          double pct(double value) =>
              widget.totalAmount <= 0 ? 0 : (value / widget.totalAmount) * 100;
          String pctText(double value) => '${pct(value).toStringAsFixed(1)}%';
          // Clamped only for the progress-bar segment width.
          double barValue(double value) => pct(value).clamp(0, 100).toDouble();

          String labelFor(String name, double amount) =>
              '$name\n${formatAmount(amount)} (${pctText(amount)})';

          // Keep Net Paid and Outstanding as the first-row items
          final netPaidItem = ProgressItemHelper(
            label: labelFor('Net Paid', widget.netPaidAmount),
            value: barValue(widget.netPaidAmount),
            color: Colors.greenAccent.shade100,
          );

          final outstandingItem = ProgressItemHelper(
            label: labelFor('Outstanding', widget.outstandingAmount),
            value: barValue(widget.outstandingAmount),
            color: Colors.redAccent.shade100,
          );

          final inProcessItem = ProgressItemHelper(
            label: labelFor('In Process', widget.inProcessAmount),
            value: barValue(widget.inProcessAmount),
            color: Colors.yellow,
          );

          final refundItem = ProgressItemHelper(
            label: labelFor('Refund', widget.refundedAmount),
            value: barValue(widget.refundedAmount),
            color: AppColors.refundLegendColor,
          );

          final paidItem = ProgressItemHelper(
            label: labelFor('Paid', widget.paidAmount),
            value: barValue(widget.paidAmount),
            color: AppColors.paidLegendColor,
          );

          final collapsedItems = <ProgressItemHelper>[
            netPaidItem,
            outstandingItem,
          ];

          final expandedItems = <ProgressItemHelper>[
            netPaidItem,
            outstandingItem,
            inProcessItem,
            refundItem,
            paidItem,
          ];

          final itemsToShow = _isExpanded ? expandedItems : collapsedItems;
          final progressItems = <ProgressItemHelper>[
            netPaidItem,
            outstandingItem,
            inProcessItem,
          ];

          final outstandingAmountText = formatAmount(widget.outstandingAmount);
          final outstandingPercentage = pct(
            widget.outstandingAmount,
          ).toStringAsFixed(1);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TotalOutstandingSummary(
                amountLabel: outstandingAmountText,
                percentageLabel: '$outstandingPercentage%',
              ),
              const SizedBox(height: 8),
              // Only the "Show more" / "Show less" button toggles expand/collapse —
              // tapping the card body itself does nothing.
              CustomStatBarCard(
                title: widget.title,
                number: '\$${numberFormat.format(widget.totalAmount)}',
                numberFontSize: 26,
                titleFontSize: 17,
                items: itemsToShow,
                progressItems: progressItems,
                fullWidthBar: true,
                footer: TextButton.icon(
                  onPressed: _toggleExpanded,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primaryColor,
                  ),
                  label: Text(
                    _isExpanded ? 'Show less' : 'Show more',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalOutstandingSummary extends StatelessWidget {
  const _TotalOutstandingSummary({
    required this.amountLabel,
    required this.percentageLabel,
  });

  final String amountLabel;
  final String percentageLabel;

  @override
  Widget build(BuildContext context) {
    return CustomSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Outstanding',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amountLabel,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.themeColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.refundLegendColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: AppColors.refundLegendColor,
                ),
                const SizedBox(width: 4),
                Text(
                  percentageLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.refundLegendColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
