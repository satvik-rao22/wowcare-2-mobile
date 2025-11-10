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
                        color: Color(0xff573353),
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

class _CreateInvoiceTypeCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.themeColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xff573353),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: Color(0x99573353),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}