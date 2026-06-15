import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/create_invoice_dialog.dart'
    show BillingActionCard;

/// Shown from the Transactions tab "+" button: lets the user choose between
/// creating an invoice or receiving a payment. Both flows start by selecting
/// student(s).
class TransactionActionDialog extends StatelessWidget {
  const TransactionActionDialog({
    super.key,
    this.onSelectCreateInvoice,
    this.onSelectReceivePayment,
  });

  final VoidCallback? onSelectCreateInvoice;
  final VoidCallback? onSelectReceivePayment;

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
                      'New Transaction',
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
                      child:
                          Icon(Icons.close, size: 18, color: Color(0x99573353)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'What would you like to do?',
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
                    child: BillingActionCard(
                      title: 'Create\nInvoice',
                      subtitle:
                          'Select student(s) and bill them with custom line items',
                      icon: Icons.receipt_long,
                      onTap: onSelectCreateInvoice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BillingActionCard(
                      title: 'Receive\nPayment',
                      subtitle:
                          'Select student(s) and record a payment received',
                      icon: Icons.payments_outlined,
                      onTap: onSelectReceivePayment,
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
