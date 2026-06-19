import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/auto_pay_methods_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/auto_pay_token_webview.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';

class AutoPayPaymentMethodsScreen extends StatefulWidget {
  const AutoPayPaymentMethodsScreen({super.key});

  static const String routeName = '/auto-pay-payment-methods';

  @override
  State<AutoPayPaymentMethodsScreen> createState() =>
      _AutoPayPaymentMethodsScreenState();
}

class _AutoPayPaymentMethodsScreenState
    extends State<AutoPayPaymentMethodsScreen> {
  final AutoPayMethodsCubit _cubit = serviceLocator<AutoPayMethodsCubit>();

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
        listenWhen: (prev, curr) =>
            prev.errorMessage != curr.errorMessage &&
            curr.errorMessage != null,
        listener: (context, state) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.errorMessage!,
            isError: true,
          );
        },
        builder: (context, state) {
          return StaffFormLayout(
            title: 'Auto Payment',
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAutoPayToggle(state),
                  const SizedBox(height: 16),
                  const Divider(height: 32),
                  const SizedBox(height: 16),
                  _buildSavedPaymentMethods(state),
                ],
              ),
            ),
            bottomBar: _buildBottomBar(state),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(AutoPayMethodsState state) {
    final canSave = state.canSave;
    return Container(
      padding: EdgeInsets.only(
        bottom: (MediaQuery.of(context).padding.bottom > 0)
            ? MediaQuery.of(context).padding.bottom
            : 16,
        left: 16,
        right: 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: AbsorbPointer(
        absorbing: !canSave,
        child: Opacity(
          opacity: canSave ? 1 : 0.6,
          child: CustomButtonLayout(
            confirmButtonLabel: 'Save',
            onPressedConfirm: _handleSave,
            showCancelButton: false,
            isForm: false,
            isLoading: state.isSettingPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoPayToggle(AutoPayMethodsState state) {
    final enabled = state.autopayEnabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Auto Payment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          CustomToggle(
            label: '',
            isToggled: enabled,
            onToggle: (value) => unawaited(_cubit.toggleAutoPay(value)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFE8FFF1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              enabled ? 'Enabled' : 'Disabled',
              style: TextStyle(
                color: enabled ? AppColors.successColor : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedPaymentMethods(AutoPayMethodsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Saved Payment Methods',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              '${state.methods.length}/${AutoPayMethodsState.maxMethods}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black45,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.isLoading)
          _buildLoadingTile()
        else if (!state.hasMethods)
          _buildEmptyState()
        else
          ...state.methods.map((m) => _buildMethodTile(state, m)),
        const SizedBox(height: 4),
        _buildAddMethodTile(state),
        if (state.isSaving) ...[
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Saving your payment method...',
              style: TextStyle(color: Color(0xFF718096), fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 12),
          Text('Loading saved payment methods...'),
        ],
      ),
    );
  }

  Widget _buildMethodTile(AutoPayMethodsState state, PaymentMethodEntity m) {
    final enabled = state.autopayEnabled;
    final isSelected = state.selectedMethodCode == m.code && enabled;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0FFF4) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.successColor : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.successColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (enabled)
                Radio<String>(
                  value: m.code,
                  groupValue: state.selectedMethodCode,
                  onChanged: (_) => _cubit.selectMethod(m.code),
                  activeColor: AppColors.successColor,
                )
              else
                const SizedBox(width: 40),
              Expanded(
                child: GestureDetector(
                  onTap: enabled ? () => _cubit.selectMethod(m.code) : null,
                  child: Text(
                    _methodTitle(m),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ),
              if (m.primary)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FFF1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Auto Pay',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successColor,
                    ),
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: enabled ? () => _cubit.selectMethod(m.code) : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.7,
              child: m.isEcheck ? _buildEcheckCard(m) : _buildCreditCard(m),
            ),
          ),
        ],
      ),
    );
  }

  String _methodTitle(PaymentMethodEntity m) {
    if (m.label != null && m.label!.trim().isNotEmpty) return m.label!.trim();
    if (m.isEcheck) return 'eCheck account';
    final type = m.card?.cardType ?? m.methodType.apiValue;
    return '$type card';
  }

  Widget _buildAddMethodTile(AutoPayMethodsState state) {
    final canAdd =
        state.canAddMore && state.hasForteConfig && !state.isSaving;
    return Opacity(
      opacity: canAdd ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: InkWell(
          onTap: canAdd ? _openAddMethod : null,
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: Color(0xFF667EEA)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.canAddMore
                      ? 'Use new payment method'
                      : 'Maximum of ${AutoPayMethodsState.maxMethods} methods reached',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: canAdd ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCard(PaymentMethodEntity m) {
    final card = m.card;
    final last4 = card?.last4 ?? m.last4 ?? '••••';
    final type = (card?.cardType ?? m.methodType.apiValue).toUpperCase();
    final gradient = _cardGradient(type);
    final exp = (card?.expireMonth != null && card?.expireYear != null)
        ? '${card!.expireMonth}/${card.expireYear}'
        : '--/--';
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320, minHeight: 170),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChip(),
              Text(
                type,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                '•••• •••• ••••',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                last4,
                style: const TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _detailGroup(
                'Card Holder',
                (card?.nameOnCard ?? '').toUpperCase().isEmpty
                    ? '—'
                    : card!.nameOnCard!.toUpperCase(),
              ),
              _detailGroup('Expires', exp),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcheckCard(PaymentMethodEntity m) {
    final e = m.echeck;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320, minHeight: 170),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB8DAEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'eCheck',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334455),
                ),
              ),
              Text(
                _echeckAccountTypeLabel(e?.accountType),
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _detailGroup(
                  'Account Holder Name',
                  e?.accountHolder ?? '—',
                  isDark: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailGroup(
                  'Routing Number',
                  e?.routingNumber ?? '—',
                  isDark: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailGroup(
            'Last Four',
            e?.last4 ?? m.last4 ?? '—',
            isDark: false,
          ),
        ],
      ),
    );
  }

  String _echeckAccountTypeLabel(String? accountType) {
    final lower = (accountType ?? '').toLowerCase();
    if (lower == 'c' || lower.contains('checking')) return 'Checking';
    if (lower == 's' || lower.contains('saving')) return 'Savings';
    return accountType ?? '';
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        children: [
          Icon(Icons.credit_card, size: 36, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No saved payment methods found',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  LinearGradient _cardGradient(String cardType) {
    final type = cardType.toLowerCase();
    if (type.contains('visa')) {
      return const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (type.contains('mast') || type.contains('master')) {
      return const LinearGradient(
        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (type.contains('disc')) {
      return const LinearGradient(
        colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF5B5B5B), Color(0xFF1A1A1A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildChip() {
    return Container(
      width: 40,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [Color(0xFFD1D1D1), Color(0xFFFCFCFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _detailGroup(String label, String value, {bool isDark = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    final ok = await _cubit.saveSelectedAsPrimary();
    if (!mounted) return;
    if (ok) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Auto Pay method updated',
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    }
  }

  /// Opens the Forte tokenization webview, then posts the resulting one-time
  /// token to create the saved payment method.
  Future<void> _openAddMethod() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AutoPayTokenWebView(payload: _cubit.buildWebviewPayload()),
      ),
    );
    if (!mounted || result is! Map) return;

    if (result['success'] != true) {
      final error = result['error'];
      final message = error is Map
          ? (error['response_description'] ??
                  error['response_text'] ??
                  error['error_message'] ??
                  'Unable to add payment method. Please try again.')
              .toString()
          : (error?.toString() ??
              'Unable to add payment method. Please try again.');
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
      );
      return;
    }

    final tokenData = result['data'];
    final data = tokenData is Map ? tokenData : const {};
    final oneTimeToken =
        (data['onetime_token'] ?? data['onetimeToken'])?.toString() ?? '';
    if (oneTimeToken.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Invalid payment token received from Forte. Please try again.',
        isError: true,
      );
      return;
    }

    final isEcheck =
        (result['paymentType']?.toString().toLowerCase() ?? '') == 'echeck';
    final methodType = isEcheck
        ? PaymentMethodType.echeck
        : PaymentMethodTypeX.fromApi(data['card_type']?.toString());

    final ok = await _cubit.addPaymentMethodFromToken(
      oneTimeToken: oneTimeToken,
      methodType: methodType,
    );
    if (!mounted) return;
    if (ok) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Payment method added',
        isSuccess: true,
      );
    }
  }
}
