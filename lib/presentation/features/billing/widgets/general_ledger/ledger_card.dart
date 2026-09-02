import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/theme/colors.dart';
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
          label: 'Type',
          valueWidget: ShaderMask(
            shaderCallback: (bounds) => AppColors.buildPrimaryGradient()
                .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(
              type,
              textAlign: TextAlign.right,
              style: BillingCardText.value.copyWith(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: 'Open Balance',
          value: '\$${openBalance.toStringAsFixed(0)}',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FilledActionButton(label: 'View', onTap: onView),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isActive
                  ? _FilledActionButton(label: 'Edit', onTap: onEdit)
                  : _OutlineActionButton(label: 'Reactivate', onTap: onReactivate),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: isActive
              ? _OutlineActionButton(label: 'Deactivate', onTap: onDeactivate)
              : _OutlineActionButton(label: 'Delete', onTap: onDelete),
        ),
      ],
    );
  }
}

class _FilledActionButton extends StatelessWidget {
  const _FilledActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  static const Color _accent = Color(0xFF6C7FD8);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _accent,
          ),
        ),
      ),
    );
  }
}

