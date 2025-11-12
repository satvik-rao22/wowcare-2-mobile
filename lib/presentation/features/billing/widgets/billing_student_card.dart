import 'package:flutter/material.dart';
import 'package:wowcare/core/common/widgets/expandable_info_card.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class BillingStudentCard extends StatelessWidget {
  final String name;
  final String classroom;
  final String? fileUuid;
  final double amount;
  final String paidOn;
  final String paymentMethod;
  final String paymentNote;
  final String lastPaymentStatus;
  final double lastInvoiceAmount;
  final String lastInvoiceSent;
  final String lastInvoiceDue;
  final double openBalance;
  final VoidCallback? onLongPress;

  const BillingStudentCard({
    Key? key,
    required this.name,
    required this.classroom,
    this.fileUuid,
    required this.amount,
    required this.paidOn,
    required this.paymentMethod,
    required this.paymentNote,
    required this.lastPaymentStatus,
    required this.lastInvoiceAmount,
    required this.lastInvoiceSent,
    required this.lastInvoiceDue,
    required this.openBalance,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (lastPaymentStatus) {
      case 'Success':
        statusColor = Colors.green;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'Failed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = const Color(0xff573353);
    }

    return ExpandableInfoCard(
      leading: DocumentImageWidget(
        fileUuid: fileUuid ?? '',
        name: name,
        size: 48,
        shape: BoxShape.circle,
        fit: BoxFit.cover,
        fontSize: 14,
        statusColor: statusColor,
      ),
      titleText: name,
      titleStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Color(0xff573353),
        height: 22 / 16,
      ),
      subtitleText: classroom,
      onLongPress: onLongPress,
      rows: [
        InfoRowItem(
          label: 'Payment Method',
          valueText: paymentMethod,
          noteText: paymentNote,
        ),
        InfoRowItem(
          label: 'Last Payment Status',
          valueText: lastPaymentStatus,
          valueStyle: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
        InfoRowItem(
          label: 'Last Invoice',
          valueText: '\$${lastInvoiceAmount.toStringAsFixed(0)}',
          noteText: 'SENT: $lastInvoiceSent   DUE: $lastInvoiceDue',
        ),
        InfoRowItem(
          label: 'Open Balance',
          valueText: '\$${openBalance.toStringAsFixed(0)}',
        ),
      ],
    );
  }
}


