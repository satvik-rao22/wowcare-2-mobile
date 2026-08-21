import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/staff_style_card.dart';
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

/// Statement card — styled to match the staff card.
class ParentStatementCard extends StatelessWidget {
  final DemoStatement statement;

  const ParentStatementCard({super.key, required this.statement});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return StaffStyleCard(
      leading: DocumentImageWidget(
        fileUuid: statement.photoUuid ?? '',
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
          _Badge(label: 'Statement', color: AppColors.billingPaymentBadgeColor),
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
          value: DateUtilsNew.formatToReadableDate(statement.statementDate),
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: 'Statement Period',
          value:
              '${DateUtilsNew.formatToReadableDate(statement.periodStartDate)} - ${DateUtilsNew.formatToReadableDate(statement.periodEndDate)}',
        ),
        const SizedBox(height: 16),
        StaffCardActions(
          secondaryLabel: 'View',
          onSecondary: () {
            // TODO: Navigate to statement view
          },
          primaryLabel: 'Download',
          onPrimary: () {
            // TODO: Navigate to statement download
          },
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

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
          color: AppColors.secondaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
