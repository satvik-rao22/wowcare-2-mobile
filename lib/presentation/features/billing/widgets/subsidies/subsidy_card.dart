import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/presentation/features/billing/view_model/subsidies_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/staff_style_card.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';

class SubsidyCard extends StatefulWidget {
  const SubsidyCard({
    super.key,
    required this.subsidy,
    this.onDelete,
    this.onEdit,
    this.onLongPress,
  });

  final SubsidyItem subsidy;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;

  @override
  State<SubsidyCard> createState() => _SubsidyCardState();
}

class _SubsidyCardState extends State<SubsidyCard> {
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);

  NumberFormat get _currency =>
      NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

  @override
  void dispose() {
    _isExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    final item = widget.subsidy;

    return ValueListenableBuilder<bool>(
      valueListenable: _isExpanded,
      builder: (context, isExpanded, _) => StaffStyleCard(
      isExpanded: isExpanded,
      onExpandChanged: (v) => _isExpanded.value = v,
      onLongPress: widget.onLongPress,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              item.subsidyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BillingCardText.name(isTablet),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isExpanded && item.balance != null
                ? _currency.format(item.balance)
                : '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: BillingCardText.name(isTablet),
          ),
        ],
      ),
      expandedChildren: [
        StaffCardDetailRow(
          label: 'Invoiced',
          value: _currency.format(item.invoiced),
        ),
        const SizedBox(height: 12),
        StaffCardDetailRow(
          label: 'Received',
          value: _currency.format(item.received),
        ),
        const SizedBox(height: 16),
        StaffCardActions(
          secondaryLabel: 'Delete',
          onSecondary: _confirmDelete,
          primaryLabel: 'Edit',
          onPrimary: widget.onEdit,
        ),
      ],
      ),
    );
  }

  void _confirmDelete() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.billingTransparentColor,
      builder: (ctx) {
        return DeleteConfirmationBottomSheet(
          name: widget.subsidy.subsidyName,
          type: 'subsidy',
          onDelete: () {
            Navigator.of(ctx).pop();
            widget.onDelete?.call();
            return Future.value();
          },
          onCancel: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }
}
