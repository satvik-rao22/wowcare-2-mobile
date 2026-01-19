import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                      child: Icon(Icons.close, size: 18, color: Color(0x99573353)),
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
                  color: Color(0x99573353),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CreateInvoiceTypeCard(
                      title: 'One-Time\nInvoice',
                      subtitle:
                          'Create a manual invoice for one or more students with custom line items',
                      icon: Icons.receipt_long,
                      onTap: onSelectOneTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CreateInvoiceTypeCard(
                      title: 'Recurring\nInvoice',
                      subtitle:
                          'Set up automatic recurring invoices for a student based on their schedule',
                      icon: Icons.schedule,
                      onTap: onSelectRecurring,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateInvoiceTypeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  const _CreateInvoiceTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  State<_CreateInvoiceTypeCard> createState() => _CreateInvoiceTypeCardState();
}

class _CreateInvoiceTypeCardState extends State<_CreateInvoiceTypeCard> {
  bool _isHighlighted = false;

  void _setHighlight(bool v) {
    if (_isHighlighted == v) return;
    setState(() => _isHighlighted = v);
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = _isHighlighted ? AppColors.themeColor : AppColors.cardColor;
    final Color borderColor = _isHighlighted ? AppColors.themeColor : AppColors.cardBorderColor;
    final Color primaryText = _isHighlighted ? AppColors.billingButtonTextColor : AppColors.billingTextColor;
    final Color secondaryText = _isHighlighted ? Colors.white70 : const Color(0x99573353);
    final Color iconBg = _isHighlighted ? Colors.white24 : AppColors.themeColor.withOpacity(0.1);
    final Color iconColor = _isHighlighted ? Colors.white : AppColors.themeColor;

    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: _setHighlight,
      overlayColor: MaterialStatePropertyAll(
        AppColors.themeColor.withOpacity(0.12),
      ),
      splashColor: AppColors.themeColor.withOpacity(0.16),
      highlightColor: AppColors.themeColor.withOpacity(0.1),
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
  }
}