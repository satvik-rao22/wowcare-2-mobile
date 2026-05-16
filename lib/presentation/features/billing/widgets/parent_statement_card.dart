import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_floating_text_button.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/util/date_utils.dart';

/// Demo statement data model for UI-only display
class DemoStatement {
  final String id;
  final String statementType;
  final DateTime statementDate;
  final DateTime periodStartDate;
  final DateTime periodEndDate;
  final String studentName;
  final String? photoUuid;

  const DemoStatement({
    required this.id,
    required this.statementType,
    required this.statementDate,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.studentName,
    this.photoUuid,
  });
}

/// Statement card widget matching transaction card ExpansionTile structure
class ParentStatementCard extends StatelessWidget {
  final DemoStatement statement;

  const ParentStatementCard({super.key, required this.statement});

  @override
  Widget build(BuildContext context) {
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
              'Statement',
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
            'Type: ${statement.statementType}',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(
          top: 4.0,
        ), // Align with badge top padding
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
                  'Generated on: ${DateUtilsNew.formatToReadableDate(statement.statementDate)}',
                  style: AppTextStyles.value.copyWith(
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  'Period: ${DateUtilsNew.formatToReadableDate(statement.periodStartDate)} - ${DateUtilsNew.formatToReadableDate(statement.periodEndDate)}',
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
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Divider(color: AppColors.billingDividerColor),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Student Name',
              style: AppTextStyles.label.copyWith(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DocumentImageWidget(
                  fileUuid: statement.photoUuid ?? '',
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
                          fontSize: 16,
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
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Text(
              statement.statementType,
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
              'Statement Period',
              style: AppTextStyles.label.copyWith(
                fontSize: 14,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                '${DateUtilsNew.formatToReadableDate(statement.periodStartDate)} - ${DateUtilsNew.formatToReadableDate(statement.periodEndDate)}',
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
