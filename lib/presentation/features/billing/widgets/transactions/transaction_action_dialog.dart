import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
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
    this.onSelectAddCredit,
  });

  final VoidCallback? onSelectCreateInvoice;
  final VoidCallback? onSelectReceivePayment;

  /// Optional third action (shown only when provided) — adds account credit.
  final VoidCallback? onSelectAddCredit;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppColors.billingCardColor,
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
                      BillingStrings.newTransaction,
                      style: TextStyle(
                        fontFamily: AppFonts.body,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                          Icon(Icons.close, size: 18, color: AppColors.billingTextMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                BillingStrings.whatWouldYouLikeToDo,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.billingTextMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BillingActionCard(
                      title: BillingStrings.createInvoiceAction,
                      subtitle:
                          BillingStrings.selectStudentSAndBillThem,
                      icon: Icons.receipt_long,
                      onTap: onSelectCreateInvoice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BillingActionCard(
                      title: BillingStrings.receivePaymentCard,
                      subtitle:
                          BillingStrings.selectStudentSAndRecordA,
                      icon: Icons.payments_outlined,
                      onTap: onSelectReceivePayment,
                    ),
                  ),
                ],
              ),
              if (onSelectAddCredit != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: BillingActionCard(
                        title: BillingStrings.addCreditAction,
                        subtitle:
                            BillingStrings.addAccountCreditForThis,
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: onSelectAddCredit,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
