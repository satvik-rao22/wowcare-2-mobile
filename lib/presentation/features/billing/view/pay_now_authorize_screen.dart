import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

/// Pay Now — step 3: our own authorize/confirm screen (not Forte's hosted page).
///
/// The real charge will run through the Forte Checkout v2 widget
/// (`assets/forte_checkout_v2.html`) once the authorize API exists; for now the
/// Authorize action is mocked so the flow is testable end-to-end.
class PayNowAuthorizeScreen extends StatefulWidget {
  const PayNowAuthorizeScreen({
    super.key,
    required this.method,
    required this.amount,
  });

  final PaymentMethodEntity method;
  final double amount;

  @override
  State<PayNowAuthorizeScreen> createState() => _PayNowAuthorizeScreenState();
}

class _PayNowAuthorizeScreenState extends State<PayNowAuthorizeScreen> {
  bool _authorizing = false;

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'Authorize Payment',
      bottomBar: _buildBottomBar(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('PAYMENT INFORMATION'),
            _paymentInfo(),
            const SizedBox(height: 20),
            _sectionLabel('AMOUNT SUMMARY'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount',
                    style: TextStyle(fontSize: 15, color: Colors.black54)),
                Text(
                  '\$${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF573353),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'I authorize a one-time electronic payment from the selected '
              'payment method in the amount specified above.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.grey.shade600,
          ),
        ),
      );

  Widget _paymentInfo() {
    final m = widget.method;
    final last4 = m.isEcheck
        ? (m.echeck?.last4 ?? m.last4 ?? '••••')
        : (m.card?.last4 ?? m.last4 ?? '••••');
    final holder = m.isEcheck ? m.echeck?.accountHolder : m.card?.nameOnCard;
    final brand = m.isEcheck
        ? 'Bank Account (ACH)'
        : (m.card?.cardType ?? m.methodType.apiValue).toUpperCase();
    final exp = (m.card?.expireMonth != null && m.card?.expireYear != null)
        ? 'Exp. ${m.card!.expireMonth.toString().padLeft(2, '0')}/${m.card!.expireYear}'
        : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(m.isEcheck ? Icons.account_balance : Icons.credit_card,
              color: const Color(0xFF667EEA), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((holder ?? '').trim().isNotEmpty)
                  Text(
                    holder!.trim(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                Text(
                  '$brand •••• $last4',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (exp != null)
                  Text(
                    exp,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F9D58),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: (MediaQuery.of(context).padding.bottom > 0)
            ? MediaQuery.of(context).padding.bottom
            : 16,
        left: 16,
        right: 16,
        top: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: InkWell(
        onTap: _authorizing ? null : _authorize,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.buildPrimaryGradient(),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _authorizing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Authorize \$${widget.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Mocked authorize: no backend authorize API yet. Simulates success and
  /// closes the whole Pay Now flow.
  Future<void> _authorize() async {
    setState(() => _authorizing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _authorizing = false);
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Payment authorized successfully',
      isSuccess: true,
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
