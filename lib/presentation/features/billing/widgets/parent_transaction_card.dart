import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/staff_style_card.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/util/date_utils.dart';

/// Demo transaction data model for UI-only display
class DemoTransaction {
  final String id;
  final String type; // 'Payment', 'Invoice', 'Refund'
  final double amount;
  final DateTime date;
  final String status; // 'Completed', 'In Process', 'Cancelled'
  final String? paymentMode;
  final String description;
  final String studentName;
  final String studentRoom;

  const DemoTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
    this.paymentMode,
    required this.description,
    required this.studentName,
    required this.studentRoom,
  });
}

/// Demo statement data model for UI-only display
class DemoStatement {
  final String id;
  final String studentName;
  final String statementType; // e.g. 'Yearly', 'Monthly', 'Custom'
  final DateTime generatedOn;
  final DateTime periodFrom;
  final DateTime periodTo;

  const DemoStatement({
    required this.id,
    required this.studentName,
    required this.statementType,
    required this.generatedOn,
    required this.periodFrom,
    required this.periodTo,
  });
}

/// Example demo statements – use these in your UI list/grid as needed
final List<DemoStatement> demoStatements = [
  DemoStatement(
    id: 'st_001',
    studentName: 'Lux Stud',
    statementType: 'Yearly',
    generatedOn: DateTime(2026, 1, 22),
    periodFrom: DateTime(2026, 1, 1),
    periodTo: DateTime(2026, 12, 31),
  ),
  DemoStatement(
    id: 'st_002',
    studentName: 'Lux Stud',
    statementType: 'Monthly',
    generatedOn: DateTime(2026, 1, 22),
    periodFrom: DateTime(2026, 1, 1),
    periodTo: DateTime(2026, 1, 31),
  ),
];

/// Transaction card — styled to match the staff card.
class ParentTransactionCard extends StatelessWidget {
  final DemoTransaction transaction;

  const ParentTransactionCard({
    super.key,
    required this.transaction,
  });

  String get _type => transaction.type.toLowerCase();

  String _dateLabel() {
    final date = DateUtilsNew.formatToReadableDate(transaction.date);
    switch (_type) {
      case 'invoice':
        return 'Due Date: $date';
      case 'refund':
        return 'Refunded On: $date';
      default:
        return 'Paid On: $date';
    }
  }

  ({String label, Color color, Color textColor}) _badge() {
    switch (_type) {
      case 'invoice':
        return (
          label: 'Invoice',
          color: AppColors.billingInvoiceBadgeColor,
          textColor: AppColors.secondaryColor,
        );
      case 'refund':
        return (
          label: 'Refund',
          color: AppColors.billingRefundBadgeColor,
          textColor: AppColors.billingGreyDark,
        );
      default:
        return (
          label: 'Payment',
          color: AppColors.billingPaymentBadgeColor,
          textColor: AppColors.secondaryColor,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final badge = _badge();

    final expanded = <Widget>[];
    if (transaction.paymentMode != null &&
        transaction.paymentMode!.isNotEmpty &&
        _type != 'invoice') {
      expanded
        ..add(StaffCardDetailRow(
          label: 'Payment Method',
          value: transaction.paymentMode!,
        ))
        ..add(const SizedBox(height: 10));
    }
    expanded.add(StaffCardDetailRow(
      label: 'Status',
      value: transaction.status,
    ));
    expanded.add(const SizedBox(height: 10));
    expanded.add(StaffCardDetailRow(
      label: 'Description',
      value: transaction.description,
    ));
    if (_type == 'payment') {
      expanded
        ..add(const SizedBox(height: 16))
        ..add(StaffCardActions(
          primaryLabel: 'View Receipt',
          onPrimary: () {/* TODO: receipt */},
        ));
    } else if (_type == 'invoice') {
      expanded
        ..add(const SizedBox(height: 16))
        ..add(StaffCardActions(
          primaryLabel: 'View Invoice',
          onPrimary: () {/* TODO: invoice */},
        ));
    }

    return StaffStyleCard(
      leading: DocumentImageWidget(
        fileUuid: '',
        name: transaction.studentName,
        size: 50,
      ),
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.studentName,
                  style: BillingCardText.name(isTablet),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                _Badge(label: badge.label, color: badge.color, textColor: badge.textColor),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${transaction.amount.toStringAsFixed(2)}',
                style: BillingCardText.name(isTablet)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _dateLabel(),
                style: BillingCardText.note,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
      expandedChildren: expanded,
    );
  }
}

/// Statement card — styled to match the staff card.
class ParentStatementCard extends StatelessWidget {
  final DemoStatement statement;

  const ParentStatementCard({
    super.key,
    required this.statement,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return StaffStyleCard(
      leading: DocumentImageWidget(
        fileUuid: '',
        name: statement.studentName,
        size: 50,
      ),
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              statement.studentName,
              style: BillingCardText.name(isTablet),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _Badge(
            label: 'Statement',
            color: AppColors.billingPaymentBadgeColor,
            textColor: AppColors.secondaryColor,
          ),
        ],
      ),
      expandedChildren: [
        StaffCardDetailRow(
          label: 'Statement Type',
          value: statement.statementType,
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: 'Generated On',
          value: DateUtilsNew.formatToReadableDate(statement.generatedOn),
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: 'Statement Period',
          value:
              '${DateUtilsNew.formatToReadableDate(statement.periodFrom)} - ${DateUtilsNew.formatToReadableDate(statement.periodTo)}',
        ),
        const SizedBox(height: 16),
        StaffCardActions(
          secondaryLabel: 'View',
          onSecondary: () {/* TODO: view */},
          primaryLabel: 'Download',
          onPrimary: () {/* TODO: download */},
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: BillingCardText.label.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
