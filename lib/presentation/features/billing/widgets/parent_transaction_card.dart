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
                fontSize: 16,
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
                    fontSize: 14,
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
                fontSize: 14,
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
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                transaction.description,
                style: AppTextStyles.value.copyWith(
                  fontSize: 16,
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
                fontSize: 16,
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
                    fontSize: 14,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Name',
              style: AppTextStyles.label.copyWith(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.end,
            ),
            const SizedBox(height: 5),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.studentName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.value.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.studentRoom,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 13,
                          color: AppColors.primaryColor,
                        ),
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
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                transaction.description,
                style: AppTextStyles.value.copyWith(
                  fontSize: 16,
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
                fontSize: 16,
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
                    fontSize: 14,
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
                fontSize: 14,
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
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                transaction.description,
                style: AppTextStyles.value.copyWith(
                  fontSize: 16,
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

