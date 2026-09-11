import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/widgets/staff_style_card.dart';

class DiscountCard extends StatelessWidget {
  const DiscountCard({
    super.key,
    required this.name,
    required this.percentage,
    required this.totalAmountDiscounted,
    required this.isActive,
    this.onView,
    this.onEdit,
    this.onDeactivate,
    this.onReactivate,
    this.onDelete,
  });

  final String name;
  final double percentage;
  final double totalAmountDiscounted;
  final bool isActive;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveHelper(context).isTabletCompact;
    return StaffStyleCard(
      header: Text(
        name,
        style: BillingCardText.name(isTablet),
        overflow: TextOverflow.ellipsis,
      ),
      expandedChildren: [
        StaffCardDetailRow(
          label: BillingStrings.percentage,
          valueWidget: ShaderMask(
            shaderCallback: (bounds) => AppColors.buildPrimaryGradient()
                .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: BillingCardText.value.copyWith(color: AppColors.billingCardOnColorText),
            ),
          ),
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: BillingStrings.totalDiscounted,
          value: '\$${totalAmountDiscounted.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlineActionButton(label: BillingStrings.view, onTap: onView),
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
