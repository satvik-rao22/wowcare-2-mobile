import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_floating_text_button.dart';
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

/// Transaction card widget matching legacy billing screen ExpansionTile structure
class ParentTransactionCard extends StatelessWidget {
  final DemoTransaction transaction;

  const ParentTransactionCard({
    super.key,
    required this.transaction,
  });

  Widget _buildPaymentTile() {
    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.trailing,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.billingPaymentBadgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Payment',
              style: AppTextStyles.value.copyWith(
                fontSize: 14,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Status: ${transaction.status}',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(top: 4.0), // Align with badge top padding
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 20,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  'Paid On: ${DateUtilsNew.formatToReadableDate(transaction.date)}',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 13,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
      iconColor: Colors.transparent,
      collapsedIconColor: Colors.transparent,
      backgroundColor: AppColors.cardColor,
      collapsedBackgroundColor: AppColors.cardColor,
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Divider(
          color: AppColors.billingDividerColor,
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Method',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              transaction.paymentMode ?? 'N/A',
              style: AppTextStyles.value.copyWith(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                transaction.description,
                style: AppTextStyles.value.copyWith(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CustomFloatingTextButton(
                onPressed: () {
                  // TODO: Navigate to receipt view
                },
                label: 'View Receipt',
                textStyle: AppTextStyles.button(
                  color: AppColors.billingButtonTextColor,
                ),
                isFilled: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoiceTile() {
    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.trailing,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.billingInvoiceBadgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Invoice',
              style: AppTextStyles.value.copyWith(
                fontSize: 14,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Status: ${transaction.status}',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(top: 4.0), // Align with badge top padding
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 20,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  'Due Date: ${DateUtilsNew.formatToReadableDate(transaction.date)}',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 13,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
      iconColor: Colors.transparent,
      collapsedIconColor: Colors.transparent,
      backgroundColor: AppColors.cardColor,
      collapsedBackgroundColor: AppColors.cardColor,
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Divider(
          color: AppColors.billingDividerColor,
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Student Name',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DocumentImageWidget(
                  fileUuid: '',
                  name: transaction.studentName,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.studentName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.value.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.studentRoom,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 13,
                          color: AppColors.primaryColor,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                transaction.description,
                style: AppTextStyles.value.copyWith(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CustomFloatingTextButton(
                onPressed: () {
                  // TODO: Navigate to invoice view
                },
                label: 'View Invoice',
                textStyle: AppTextStyles.button(
                  color: AppColors.billingButtonTextColor,
                ),
                isFilled: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefundTile() {
    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.trailing,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.billingRefundBadgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Refund',
              style: AppTextStyles.value.copyWith(
                fontSize: 14,
                color: AppColors.billingGreyDark,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Status: ${transaction.status}',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(top: 4.0), // Align with badge top padding
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 20,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  'Paid On: ${DateUtilsNew.formatToReadableDate(transaction.date)}',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 13,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
      iconColor: Colors.transparent,
      collapsedIconColor: Colors.transparent,
      backgroundColor: AppColors.cardColor,
      collapsedBackgroundColor: AppColors.cardColor,
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Divider(
          color: AppColors.billingDividerColor,
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Method',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              transaction.paymentMode ?? 'N/A',
              style: AppTextStyles.value.copyWith(
                fontSize: 16,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Description',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                transaction.description,
                style: AppTextStyles.value.copyWith(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (transaction.type) {
      case 'Payment':
        return _buildPaymentTile();
      case 'Invoice':
        return _buildInvoiceTile();
      case 'Refund':
        return _buildRefundTile();
      default:
        return _buildPaymentTile();
    }
  }
}

/// Statement card widget matching transaction card ExpansionTile structure
class ParentStatementCard extends StatelessWidget {
  final DemoStatement statement;

  const ParentStatementCard({
    super.key,
    required this.statement,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.trailing,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.billingPaymentBadgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Statement',
              style: AppTextStyles.value.copyWith(
                fontSize: 14,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Type: ${statement.statementType}',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(top: 4.0), // Align with badge top padding
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Generated on: ${DateUtilsNew.formatToReadableDate(statement.generatedOn)}',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 13,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 160,
                  child: Text(
                    'Period: ${DateUtilsNew.formatToReadableDate(statement.periodFrom)} - ${DateUtilsNew.formatToReadableDate(statement.periodTo)}',
                    style: AppTextStyles.value.copyWith(
                      fontSize: 13,
                      color: AppColors.primaryColor,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      iconColor: Colors.transparent,
      collapsedIconColor: Colors.transparent,
      backgroundColor: AppColors.cardColor,
      collapsedBackgroundColor: AppColors.cardColor,
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        Divider(
          color: AppColors.billingDividerColor,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Student Name',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DocumentImageWidget(
                  fileUuid: '',
                  name: statement.studentName,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statement.studentName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.value.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Statement Type',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              statement.statementType,
              style: AppTextStyles.value.copyWith(
                fontSize: 14,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Statement Period',
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                '${DateUtilsNew.formatToReadableDate(statement.periodFrom)} - ${DateUtilsNew.formatToReadableDate(statement.periodTo)}',
                style: AppTextStyles.value.copyWith(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CustomFloatingTextButton(
                onPressed: () {
                  // TODO: Navigate to statement view
                },
                label: 'View',
                textStyle: AppTextStyles.button(
                  color: AppColors.billingButtonTextColor,
                ),
                isFilled: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomFloatingTextButton(
                onPressed: () {
                  // TODO: Navigate to statement download
                },
                label: 'Download',
                textStyle: AppTextStyles.button(
                  color: AppColors.billingButtonTextColor,
                ),
                isFilled: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

