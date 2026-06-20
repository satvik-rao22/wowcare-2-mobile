import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/auto_pay_methods_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/pay_now_authorize_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/auto_pay_token_webview.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';

/// Pay Now — step 2: pick a saved payment method (or add one). When the
/// guardian has no saved method, the Forte add-card page opens automatically
/// and returns here once a method is added.
class PayNowMethodPickerScreen extends StatefulWidget {
  const PayNowMethodPickerScreen({super.key, required this.amount});

  final double amount;

  @override
  State<PayNowMethodPickerScreen> createState() =>
      _PayNowMethodPickerScreenState();
}

class _PayNowMethodPickerScreenState extends State<PayNowMethodPickerScreen> {
  static const Color _accent = Color(0xFF6F8CFF);

  final AutoPayMethodsCubit _cubit = serviceLocator<AutoPayMethodsCubit>();
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AutoPayMethodsCubit>.value(
      value: _cubit,
      child: BlocConsumer<AutoPayMethodsCubit, AutoPayMethodsState>(
        listenWhen: (p, c) =>
            p.errorMessage != c.errorMessage && c.errorMessage != null,
        listener: (context, state) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.errorMessage!,
            isError: true,
          );
        },
        builder: (context, state) {
          // Default the selection to the primary/first method.
          _selectedCode ??= state.methods.isNotEmpty
              ? (state.primaryMethod?.code ?? state.methods.first.code)
              : null;
          return StaffFormLayout(
            title: 'Select Payment Method',
            bottomBar: _buildBottomBar(state),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _amountBanner(),
                  const SizedBox(height: 16),
                  if (state.isLoading)
                    _buildLoading()
                  else if (!state.hasMethods)
                    _buildEmpty(state)
                  else ...[
                    for (final m in state.methods) _methodTile(state, m),
                    const SizedBox(height: 4),
                    _addTile(state),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _amountBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Amount to pay',
              style: TextStyle(fontSize: 14, color: Color(0xFF4A4A68))),
          Text(
            '\$${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF573353),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() => Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerLoader(
              height: 72,
              width: double.infinity,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );

  Widget _buildEmpty(AutoPayMethodsState state) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Column(
            children: [
              Icon(Icons.credit_card_off_outlined,
                  size: 36, color: Colors.grey),
              SizedBox(height: 8),
              Text('No saved payment methods yet.',
                  style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _addTile(state),
      ],
    );
  }

  Widget _methodTile(AutoPayMethodsState state, PaymentMethodEntity m) {
    final selected = _selectedCode == m.code;
    final last4 = m.isEcheck
        ? (m.echeck?.last4 ?? m.last4 ?? '••••')
        : (m.card?.last4 ?? m.last4 ?? '••••');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF1FFF6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.successColor : Colors.grey.shade200,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: m.code,
            groupValue: _selectedCode,
            activeColor: _accent,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (_) => setState(() => _selectedCode = m.code),
          ),
          const SizedBox(width: 4),
          Icon(m.isEcheck ? Icons.account_balance : Icons.credit_card,
              color: const Color(0xFF667EEA)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(m),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '•••• $last4',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (m.primary)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.star, color: Color(0xFFFDB813), size: 18),
            ),
        ],
      ),
    );
  }

  String _title(PaymentMethodEntity m) {
    if (m.label != null && m.label!.trim().isNotEmpty) return m.label!.trim();
    if (m.isEcheck) return 'Bank Account (ACH)';
    switch (m.methodType) {
      case PaymentMethodType.visa:
        return 'Visa';
      case PaymentMethodType.mast:
        return 'Mastercard';
      case PaymentMethodType.discover:
        return 'Discover';
      default:
        return 'Card';
    }
  }

  Widget _addTile(AutoPayMethodsState state) {
    final canAdd = state.canAddMore && state.hasForteConfig && !state.isSaving;
    return Opacity(
      opacity: canAdd ? 1 : 0.6,
      child: InkWell(
        onTap: canAdd ? _openAddMethod : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F6FD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x596F52FF)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF6F52FF)),
              SizedBox(width: 8),
              Text(
                'Add new payment method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6F52FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(AutoPayMethodsState state) {
    final canContinue =
        _selectedCode != null && !state.isLoading && !state.isSaving;
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
      child: Opacity(
        opacity: canContinue ? 1 : 0.5,
        child: InkWell(
          onTap: canContinue ? _continue : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: state.isSaving
                ? const Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _continue() {
    final method = _cubit.state.methods.firstWhere(
      (m) => m.code == _selectedCode,
      orElse: () => _cubit.state.methods.first,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PayNowAuthorizeScreen(method: method, amount: widget.amount),
      ),
    );
  }

  Future<void> _openAddMethod() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AutoPayTokenWebView(
          payload: _cubit.buildWebviewPayload(title: 'Add Payment Method'),
        ),
      ),
    );
    if (!mounted || result is! Map) return;
    if (result['success'] != true) return;

    final data = result['data'] is Map ? result['data'] as Map : const {};
    final token =
        (data['onetime_token'] ?? data['onetimeToken'])?.toString() ?? '';
    if (token.isEmpty) return;
    final isEcheck =
        (result['paymentType']?.toString().toLowerCase() ?? '') == 'echeck';
    final type = isEcheck
        ? PaymentMethodType.echeck
        : PaymentMethodTypeX.fromApi(data['card_type']?.toString());

    final ok = await _cubit.addPaymentMethodFromToken(
      oneTimeToken: token,
      methodType: type,
      accountHolder: result['accountHolder']?.toString(),
      makePrimary: result['makePrimary'] == true,
      makeAutopay: result['makeAutopay'] == true,
    );
    if (!mounted) return;
    if (ok && _cubit.state.methods.isNotEmpty) {
      setState(() => _selectedCode = _cubit.state.methods.last.code);
    }
  }
}
