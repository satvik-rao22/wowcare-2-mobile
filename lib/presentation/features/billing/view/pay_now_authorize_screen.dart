import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

/// Pay Now — step 3: review + authorize. Our own screen (not Forte's hosted
/// page). There is no authorize API yet, so Confirm Payment is mocked.
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
  static const Color _accent = Color(0xFF6F8CFF);

  bool _authorizing = false;

  bool get _isEcheck => widget.method.isEcheck;

  /// 3% for cards, flat $1.00 for ACH (matches the add-method fee note).
  double get _fee => _isEcheck ? 1.00 : widget.amount * 0.03;
  double get _total => widget.amount + _fee;

  TextStyle _t(double size, FontWeight weight, Color color,
          {double? spacing}) =>
      TextStyle(
        fontFamily: 'Manrope',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
      );

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'Pay Now',
      bottomBar: const SizedBox.shrink(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Review Payment',
                    style: _t(18, FontWeight.w700, AppColors.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                _secureChip(),
              ],
            ),
            const SizedBox(height: 14),
            _reviewCard(),
            const SizedBox(height: 28),
            Center(child: _confirmButton()),
            const SizedBox(height: 14),
            Center(child: _secureFooter()),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _secureChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FFF1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined,
              size: 14, color: AppColors.successColor),
          const SizedBox(width: 6),
          Text(
            'Secure & Encrypted',
            style: _t(12, FontWeight.w600, AppColors.successColor),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard() {
    final m = widget.method;
    final last4 = _isEcheck
        ? (m.echeck?.last4 ?? m.last4 ?? '••••')
        : (m.card?.last4 ?? m.last4 ?? '••••');
    final holder =
        (_isEcheck ? m.echeck?.accountHolder : m.card?.nameOnCard)?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isEcheck ? Icons.account_balance : Icons.credit_card,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _brand(),
                      style: _t(17, FontWeight.w800, AppColors.primaryColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '••••  ••••  ••••  $last4',
                      style: _t(14, FontWeight.w500,
                          AppColors.primaryColor.withValues(alpha: 0.7),
                          spacing: 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEcheck ? 'ACCOUNT HOLDER' : 'CARD HOLDER',
                      style: _t(11, FontWeight.w700,
                          AppColors.primaryColor.withValues(alpha: 0.45),
                          spacing: 0.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      holder.isEmpty ? '—' : holder.toUpperCase(),
                      style: _t(14, FontWeight.w600, AppColors.primaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
              color: AppColors.primaryColor.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 14),
          _amountRow('Payment Amount', widget.amount),
          const SizedBox(height: 10),
          _amountRow(
            _isEcheck ? 'Convenience Fee (\$1.00)' : 'Convenience Fee (3%)',
            _fee,
          ),
          const SizedBox(height: 12),
          _dashedDivider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style: _t(16, FontWeight.w800, AppColors.primaryColor)),
              Text('\$${_money(_total)}',
                  style: _t(20, FontWeight.w800, _accent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: _t(14, FontWeight.w500,
                AppColors.primaryColor.withValues(alpha: 0.7))),
        Text('\$${_money(value)}',
            style: _t(15, FontWeight.w700, AppColors.primaryColor)),
      ],
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashW = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashW + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 1,
              color: AppColors.primaryColor.withValues(alpha: 0.18),
            ),
          ),
        );
      },
    );
  }

  Widget _confirmButton() {
    return InkWell(
      onTap: _authorizing ? null : _confirm,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 15),
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _authorizing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text('Confirm Payment',
                style: _t(16, FontWeight.w700, Colors.white)),
      ),
    );
  }

  Widget _secureFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline,
            size: 14, color: AppColors.primaryColor.withValues(alpha: 0.45)),
        const SizedBox(width: 6),
        Text(
          'Your payment information is secure and encrypted.',
          style: _t(12, FontWeight.w500,
              AppColors.primaryColor.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  String _brand() {
    final m = widget.method;
    if (m.isEcheck) return 'Bank Account (ACH)';
    switch (m.methodType) {
      case PaymentMethodType.visa:
        return 'Visa';
      case PaymentMethodType.mast:
        return 'Mastercard';
      case PaymentMethodType.discover:
        return 'Discover';
      default:
        final ct = (m.card?.cardType ?? '').trim();
        return ct.isNotEmpty ? ct : 'Card';
    }
  }

  /// Mocked confirm: no backend authorize API yet. Simulates success and closes
  /// the whole Pay Now flow.
  Future<void> _confirm() async {
    setState(() => _authorizing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _authorizing = false);
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Payment of \$${_money(_total)} confirmed',
      isSuccess: true,
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _money(double v) => v.toStringAsFixed(2);
}
