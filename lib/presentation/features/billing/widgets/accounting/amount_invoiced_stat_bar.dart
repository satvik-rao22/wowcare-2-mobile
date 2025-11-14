import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';

class AmountInvoicedStatBar extends StatelessWidget {
  final double totalAmount;
  final double paidPercentage;
  final double inProcessPercentage;
  final double unpaidPercentage;
  final String title;

  const AmountInvoicedStatBar({
    super.key,
    required this.totalAmount,
    required this.paidPercentage,
    required this.inProcessPercentage,
    required this.unpaidPercentage,
    this.title = 'Amount Invoiced',
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0');
    String formatAmount(double value) => '\$${numberFormat.format(value)}';
    const double dummyRefundAmount = 2500;
    const double dummyRefundPercentage = 12.5;
    const double dummyPaidAmount = 79865321;
    const double dummyPaidPercentage = 72.0;
    final double paidAmt =
        (totalAmount * (paidPercentage.clamp(0, 100) / 100)).clamp(0, totalAmount);
    final double inProcessAmt =
        (totalAmount * (inProcessPercentage.clamp(0, 100) / 100)).clamp(0, totalAmount);
    final double unpaidAmt =
        (totalAmount * (unpaidPercentage.clamp(0, 100) / 100)).clamp(0, totalAmount);

    return CustomStatBarCard(
      title: title,
      number: '\$${numberFormat.format(totalAmount)}',
      numberFontSize: 26,
      titleFontSize: 17,
      items: [
        ProgressItemHelper(
          label:
              'Net Paid\n${formatAmount(paidAmt)} (${paidPercentage.clamp(0, 100).toStringAsFixed(1)}%)',
          value: paidPercentage.clamp(0, 100).toDouble(),
          color: Colors.greenAccent.shade100,
        ),
        ProgressItemHelper(
          label:
              'In Process\n${formatAmount(inProcessAmt)} (${inProcessPercentage.clamp(0, 100).toStringAsFixed(1)}%)',
          value: inProcessPercentage.clamp(0, 100).toDouble(),
          color: Colors.yellow,
        ),
        ProgressItemHelper(
          label:
              'Outstanding\n${formatAmount(unpaidAmt)} (${unpaidPercentage.clamp(0, 100).toStringAsFixed(1)}%)',
          value: unpaidPercentage.clamp(0, 100).toDouble(),
          color: Colors.redAccent.shade100,
        ),
        ProgressItemHelper(
          label:
              'Refund\n${formatAmount(dummyRefundAmount)} (${dummyRefundPercentage.toStringAsFixed(1)}%)',
          value: dummyRefundPercentage,
          color: AppColors.refundLegendColor,
        ),
        ProgressItemHelper(
          label:
              'Paid\n${formatAmount(dummyPaidAmount)} (${dummyPaidPercentage.toStringAsFixed(1)}%)',
          value: dummyPaidPercentage,
          color: AppColors.paidLegendColor,
        ),
      ],
      fullWidthBar: true,
    );
  }
}


