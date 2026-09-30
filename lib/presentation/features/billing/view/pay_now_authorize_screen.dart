import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/entities/payment_settings_entity.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/pay_now_authorize_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// Pay Now — step 3: review + authorize. Charges the selected saved method via
/// `POST /payment-gateway/guardian/pay`, using the idempotency key created on
/// step 2 so retries don't double-charge.
class PayNowAuthorizeScreen extends StatefulWidget {
  const PayNowAuthorizeScreen({
    super.key,
    required this.method,
    required this.amount,
    required this.charges,
    required this.settings,
  });

  static const String routeName = '/billing/pay-now-authorize';

  final PaymentMethodEntity method;

  /// Total across all family charges (for the review/fee display).
  final double amount;

  /// One charge per family being paid; each carries its own `MOBILE-<uuid>`
  /// idempotency key minted on step 2 and reused across retries.
  final List<PayNowCharge> charges;

  /// School payment settings, preloaded earlier in the Pay Now flow so the
  /// convenience-fee row renders correctly on the first frame (no flicker).
  final PaymentSettingsEntity settings;

  @override
  State<PayNowAuthorizeScreen> createState() => _PayNowAuthorizeScreenState();
}

class _PayNowAuthorizeScreenState extends State<PayNowAuthorizeScreen> {
  static const Color _accent = AppColors.billingAccentBlue;

  final PayNowAuthorizeCubit _cubit = serviceLocator<PayNowAuthorizeCubit>();

  bool get _authorizing => _cubit.state.isSubmitting;

  bool get _isEcheck => widget.method.isEcheck;

  PaymentSettingsEntity get _settings => widget.settings;

  /// The convenience fee is only charged to (and shown to) the parent when the
  /// school's settings say the parent pays it for this method type. For ACH that
  /// is `achFeePaidBy == PARENT`; for cards, the card fee payer.
  bool _feeApplies(PaymentSettingsEntity s) =>
      _isEcheck ? s.achFeePaidByParent : s.cardFeePaidByParent;

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  /// Holder name sent to the gateway (card or ACH account holder).
  String get _holderName {
    final m = widget.method;
    final raw =
        (_isEcheck ? m.echeck?.accountHolder : m.card?.nameOnCard) ??
        m.label ??
        '';
    return raw.trim();
  }

  /// 3% for cards, flat $1.00 for ACH (matches the add-method fee note) — only
  /// when the parent actually pays the fee for this method type, else $0.
  double _feeFor(PaymentSettingsEntity s) =>
      _feeApplies(s) ? (_isEcheck ? 1.00 : widget.amount * 0.03) : 0.0;
  double _totalFor(PaymentSettingsEntity s) => widget.amount + _feeFor(s);

  TextStyle _t(
    double size,
    FontWeight weight,
    Color color, {
    double? spacing,
  }) => TextStyle(
    fontFamily: AppFonts.body,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PayNowAuthorizeCubit>.value(
      value: _cubit,
      child: BlocBuilder<PayNowAuthorizeCubit, PayNowAuthorizeState>(
        builder: (context, _) => _buildContent(context, _settings),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentSettingsEntity settings) {
    return StaffFormLayout(
      title: BillingStrings.payNow,
      bottomBar: const SizedBox.shrink(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    BillingStrings.reviewPayment,
                    style: _t(18, FontWeight.w700, AppColors.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                _secureChip(),
              ],
            ),
            const SizedBox(height: 14),
            _reviewCard(settings),
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
        color: AppColors.billingSuccessBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 14,
            color: AppColors.successColor,
          ),
          const SizedBox(width: 6),
          Text(
            BillingStrings.secureAndEncrypted,
            style: _t(12, FontWeight.w600, AppColors.successColor),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(PaymentSettingsEntity settings) {
    final m = widget.method;
    final bool showFee = _feeApplies(settings);
    final double fee = _feeFor(settings);
    final double total = _totalFor(settings);
    final last4 = _isEcheck
        ? (m.echeck?.last4 ?? m.last4 ?? '••••')
        : (m.card?.last4 ?? m.last4 ?? '••••');
    final holder =
        (_isEcheck ? m.echeck?.accountHolder : m.card?.nameOnCard)?.trim() ??
        '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withValues(alpha: 0.04),
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
              SkeuKeyBox(
                variant: KeyVariant.primary,
                radius: 14,
                width: 56,
                height: 56,
                child: Icon(
                  _isEcheck ? Icons.account_balance : Icons.credit_card,
                  color: AppColors.billingCardOnColorText,
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
                      style: _t(
                        14,
                        FontWeight.w500,
                        AppColors.primaryColor.withValues(alpha: 0.7),
                        spacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEcheck
                          ? BillingStrings.accountHolder
                          : BillingStrings.cardHolderCaps,
                      style: _t(
                        11,
                        FontWeight.w700,
                        AppColors.primaryColor.withValues(alpha: 0.45),
                        spacing: 0.4,
                      ),
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
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            height: 1,
          ),
          const SizedBox(height: 14),
          _amountRow(BillingStrings.paymentAmount, widget.amount),
          if (showFee) ...[
            const SizedBox(height: 10),
            _amountRow(
              _isEcheck
                  ? BillingStrings.convenienceFee100
                  : BillingStrings.convenienceFee3,
              fee,
            ),
          ],
          const SizedBox(height: 12),
          _dashedDivider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                BillingStrings.totalAmount,
                style: _t(16, FontWeight.w800, AppColors.primaryColor),
              ),
              Text(
                '\$${_money(total)}',
                style: _t(20, FontWeight.w800, _accent),
              ),
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
        Text(
          label,
          style: _t(
            14,
            FontWeight.w500,
            AppColors.primaryColor.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '\$${_money(value)}',
          style: _t(15, FontWeight.w700, AppColors.primaryColor),
        ),
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
      child: SkeuKeyBox(
        variant: KeyVariant.primary,
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 15),
        child: _authorizing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.billingCardOnColorText,
                  ),
                ),
              )
            : Text(
                BillingStrings.confirmPayment,
                style: _t(
                  16,
                  FontWeight.w700,
                  AppColors.billingCardOnColorText,
                ),
              ),
      ),
    );
  }

  Widget _secureFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_outline,
          size: 14,
          color: AppColors.primaryColor.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 6),
        Text(
          BillingStrings.yourPaymentInformationIsSecure,
          style: _t(
            12,
            FontWeight.w500,
            AppColors.primaryColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  String _brand() {
    final m = widget.method;
    if (m.isEcheck) return BillingStrings.bankAccountAch;
    switch (m.methodType) {
      case PaymentMethodType.visa:
        return BillingStrings.visa;
      case PaymentMethodType.mast:
        return BillingStrings.mastercard;
      case PaymentMethodType.discover:
        return BillingStrings.discover;
      default:
        final ct = (m.card?.cardType ?? '').trim();
        return ct.isNotEmpty ? ct : BillingStrings.card;
    }
  }

  /// Charges the selected method via the payment gateway. Reuses the step-2
  /// idempotency key so a retry after a failure/timeout can't double-charge.
  Future<void> _confirm() async {
    final ok = await _cubit.payMany(
      charges: widget.charges,
      paymentMethodCode: widget.method.code,
      payMethodHolderName: _holderName,
    );
    if (!mounted) return;
    if (ok) {
      final result = _cubit.state.result;
      final bool initiated =
          result != null &&
          (result.status.toUpperCase() == 'INITIATED' ||
              result.status.toUpperCase() == 'PENDING');
      final double total = _totalFor(_settings);
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Payment of \$${_money(total)} ${initiated ? 'initiated' : 'confirmed'}',
        isSuccess: true,
      );
      // Return `true` so the amount screen (and then the billing screen) can
      // reload the family ledger — the new payment shows as In Process and
      // later flips to Success/Failed once settled.
      Navigator.of(context).pop(true);
    } else {
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            _cubit.state.errorMessage ??
            BillingStrings.paymentCouldNotBeProcessed,
        isError: true,
      );
    }
  }

  String _money(double v) => v.toStringAsFixed(2);
}
