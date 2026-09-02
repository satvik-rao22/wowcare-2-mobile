import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/cubit/bool_toggle_cubit.dart';

class CreateInvoiceDialog extends StatelessWidget {
  final VoidCallback? onSelectOneTime;
  final VoidCallback? onSelectRecurring;

  const CreateInvoiceDialog({
    super.key,
    this.onSelectOneTime,
    this.onSelectRecurring,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Invoice',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.billingTextColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.billingTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Select the type of invoice you want to create:',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.billingTextMuted,
                ),
              ),
              const SizedBox(height: 16),
              BillingActionCard(
                title: 'One-Time Invoice',
                subtitle:
                    'Create a manual invoice for one or more students with custom line items',
                icon: Icons.receipt_long,
                onTap: onSelectOneTime,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BillingActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  const BillingActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  State<BillingActionCard> createState() => BillingActionCardState();
}

class BillingActionCardState extends State<BillingActionCard> {
  late final BoolToggleCubit _cubit = BoolToggleCubit();
  bool get _isHighlighted => _cubit.state;

  void _setHighlight(bool v) => _cubit.set(v);

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoolToggleCubit>.value(
      value: _cubit,
      child: BlocBuilder<BoolToggleCubit, bool>(
        builder: (context, _) {
          final Color bgColor = _isHighlighted
              ? AppColors.themeColor
              : AppColors.cardColor;
          final Color borderColor = _isHighlighted
              ? AppColors.themeColor
              : AppColors.cardBorderColor;
          final Color primaryText = _isHighlighted
              ? AppColors.billingButtonTextColor
              : AppColors.billingTextColor;
          final Color secondaryText = _isHighlighted
              ? Colors.white70
              : AppColors.billingTextMuted;
          final Color iconBg = _isHighlighted
              ? Colors.white24
              : AppColors.themeColor.withValues(alpha: 0.1);
          final Color iconColor = _isHighlighted
              ? Colors.white
              : AppColors.themeColor;

          return InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _setHighlight,
            overlayColor: MaterialStatePropertyAll(
              AppColors.themeColor.withValues(alpha: 0.12),
            ),
            splashColor: AppColors.themeColor.withValues(alpha: 0.16),
            highlightColor: AppColors.themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: secondaryText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
