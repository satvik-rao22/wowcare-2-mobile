import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/widgets/staff_style_card.dart';

class LedgerCard extends StatelessWidget {
  const LedgerCard({
    super.key,
    required this.ledgerName,
    required this.type,
    required this.openBalance,
    required this.isActive,
    this.onView,
    this.onEdit,
    this.onDeactivate,
    this.onReactivate,
    this.onDelete,
  });

  final String ledgerName;
  final String type;
  final double openBalance;
  final bool isActive;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    return StaffStyleCard(
      header: Text(
        ledgerName,
        style: BillingCardText.name(isTablet),
        overflow: TextOverflow.ellipsis,
      ),
      expandedChildren: [
        StaffCardDetailRow(
          label: BillingStrings.type,
          valueWidget: ShaderMask(
            shaderCallback: (bounds) => AppColors.buildPrimaryGradient()
                .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(
              type,
              textAlign: TextAlign.right,
              style: BillingCardText.value.copyWith(color: AppColors.billingCardOnColorText),
            ),
          ),
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: BillingStrings.openBalance,
          value: '\$${openBalance.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledActionButton(label: BillingStrings.view, onTap: onView),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isActive
                  ? FilledActionButton(label: BillingStrings.edit, onTap: onEdit)
                  : OutlineActionButton(label: BillingStrings.reactivate, onTap: onReactivate),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: isActive
              ? OutlineActionButton(label: BillingStrings.deactivate, onTap: onDeactivate)
              : OutlineActionButton(label: BillingStrings.delete, onTap: onDelete),
        ),
      ],
    );
  }
}

