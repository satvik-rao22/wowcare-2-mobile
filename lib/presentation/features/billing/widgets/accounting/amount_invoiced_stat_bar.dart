import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';

class AmountInvoicedStatBar extends StatefulWidget {
  final double totalAmount;
  final double paidPercentage;
  final double inProcessPercentage;
  final double unpaidPercentage;
  final double refundPercentage;
  final String title;

  const AmountInvoicedStatBar({
    super.key,
    required this.totalAmount,
    required this.paidPercentage,
    required this.inProcessPercentage,
    required this.unpaidPercentage,
    this.refundPercentage = 0,
    this.title = 'Amount Invoiced',
  });

  @override
  State<AmountInvoicedStatBar> createState() => _AmountInvoicedStatBarState();
}

class _AmountInvoicedStatBarState extends State<AmountInvoicedStatBar> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0');
    String formatAmount(double value) => '\$${numberFormat.format(value)}';

    final double paidAmt = (widget.totalAmount *
            (widget.paidPercentage.clamp(0, 100) / 100))
        .clamp(0, widget.totalAmount);
    final double inProcessAmt = (widget.totalAmount *
            (widget.inProcessPercentage.clamp(0, 100) / 100))
        .clamp(0, widget.totalAmount);
    final double unpaidAmt = (widget.totalAmount *
            (widget.unpaidPercentage.clamp(0, 100) / 100))
        .clamp(0, widget.totalAmount);

    // Keep Net Paid and Outstanding as the first-row items
    final netPaidItem = ProgressItemHelper(
      label:
          'Net Paid\n${formatAmount(paidAmt)} (${widget.paidPercentage.clamp(0, 100).toStringAsFixed(1)}%)',
      value: widget.paidPercentage.clamp(0, 100).toDouble(),
      color: Colors.greenAccent.shade100,
    );

    final outstandingItem = ProgressItemHelper(
      label:
          'Outstanding\n${formatAmount(unpaidAmt)} (${widget.unpaidPercentage.clamp(0, 100).toStringAsFixed(1)}%)',
      value: widget.unpaidPercentage.clamp(0, 100).toDouble(),
      color: Colors.redAccent.shade100,
    );

    final inProcessItem = ProgressItemHelper(
      label:
          'In Process\n${formatAmount(inProcessAmt)} (${widget.inProcessPercentage.clamp(0, 100).toStringAsFixed(1)}%)',
      value: widget.inProcessPercentage.clamp(0, 100).toDouble(),
      color: Colors.yellow,
    );

    final double refundAmt = widget.totalAmount *
        (widget.refundPercentage.clamp(0, 100) / 100);

    final refundItem = ProgressItemHelper(
      label:
          'Refund\n${formatAmount(refundAmt)} (${widget.refundPercentage.clamp(0, 100).toStringAsFixed(1)}%)',
      value: widget.refundPercentage.clamp(0, 100).toDouble(),
      color: AppColors.refundLegendColor,
    );

    final paidItem = ProgressItemHelper(
      label:
          'Paid\n${formatAmount(paidAmt)} (${widget.paidPercentage.clamp(0, 100).toStringAsFixed(1)}%)',
      value: widget.paidPercentage.clamp(0, 100).toDouble(),
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

    return GestureDetector(
      onTap: _toggleExpanded,
      child: CustomStatBarCard(
        title: widget.title,
        number: '\$${numberFormat.format(widget.totalAmount)}',
        numberFontSize: 26,
        titleFontSize: 17,
        items: itemsToShow,
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
    );
  }
}



