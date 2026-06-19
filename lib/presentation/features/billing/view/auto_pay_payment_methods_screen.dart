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
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class AutoPayPaymentMethodsScreen extends StatefulWidget {
  const AutoPayPaymentMethodsScreen({super.key});

  static const String routeName = '/auto-pay-payment-methods';

  @override
  State<AutoPayPaymentMethodsScreen> createState() =>
      _AutoPayPaymentMethodsScreenState();
}

class _AutoPayPaymentMethodsScreenState
    extends State<AutoPayPaymentMethodsScreen> {
  static const Color _accent = Color(0xFF6F8CFF);
  static const Color _autopayTagBg = Color(0xFFEEE9FF);
  static const Color _autopayTagFg = Color(0xFF6F52FF);

  final AutoPayMethodsCubit _cubit = serviceLocator<AutoPayMethodsCubit>();
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;
  bool _positionedToPrimary = false;

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    _pageController.dispose();
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
          _maybePositionToPrimary(state);
          return StaffFormLayout(
            title: 'AutoPay Settings',
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAutoPayHeader(state),
                  const Divider(height: 32),
                  _buildSectionHeader(),
                  const SizedBox(height: 16),
                  _buildMethodsArea(state),
                  const SizedBox(height: 16),
                  _buildAddButton(state),
                ],
              ),
            ),
            bottomBar: _buildBottomBar(state),
          );
        },
      ),
    );
  }

  // ── Header (AutoPay toggle) ────────────────────────────────────────────

  Widget _buildAutoPayHeader(AutoPayMethodsState state) {
    final enabled = state.autopayEnabled;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: _autopayTagBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.autorenew, color: _autopayTagFg, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'AutoPay',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: enabled
                          ? const Color(0xFFE8FFF1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      enabled ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: enabled ? AppColors.successColor : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Automatically pay invoices using a saved payment method.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CustomToggle(
          label: '',
          isToggled: enabled,
          onToggle: _cubit.toggleAutoPay,
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Select payment method for AutoPay',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _secureChip(),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Choose the payment method you'd like to use for automatic payments.",
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _secureChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 14, color: _autopayTagFg),
          SizedBox(width: 6),
          Text(
            'Secure & Encrypted',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A4A68),
            ),
          ),
        ],
      ),
    );
  }

  // ── Methods carousel ───────────────────────────────────────────────────

  Widget _buildMethodsArea(AutoPayMethodsState state) {
    if (state.isLoading) {
      return ShimmerLoader(
        height: 290,
        width: double.infinity,
        borderRadius: BorderRadius.circular(20),
      );
    }
    if (!state.hasMethods) return _buildEmptyState();

    final methods = state.methods;
    return Column(
      children: [
        SizedBox(
          height: 290,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: methods.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _buildMethodCard(state, methods[i]),
              ),
              if (methods.length > 1) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _arrowButton(
                    Icons.chevron_left,
                    _currentPage > 0 ? () => _animateTo(_currentPage - 1) : null,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _arrowButton(
                    Icons.chevron_right,
                    _currentPage < methods.length - 1
                        ? () => _animateTo(_currentPage + 1)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (methods.length > 1) _buildDots(methods.length),
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

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? _accent : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _arrowButton(IconData icon, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: Colors.black26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(icon, size: 22, color: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  void _animateTo(int page) {
    unawaited(
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }

  void _maybePositionToPrimary(AutoPayMethodsState state) {
    if (_positionedToPrimary || state.isLoading || !state.hasMethods) return;
    _positionedToPrimary = true;
    final idx =
        state.methods.indexWhere((m) => m.code == state.selectedMethodCode);
    final target = idx >= 0 ? idx : 0;
    if (target == 0) {
      _currentPage = 0;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(target);
      setState(() => _currentPage = target);
    });
  }

  // ── Method card (rich visual) ────────────────────────────────────────────

  Widget _buildMethodCard(AutoPayMethodsState state, PaymentMethodEntity m) {
    final selected = state.selectedMethodCode == m.code;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? _accent : Colors.grey.shade200,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.08 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Radio<String>(
                value: m.code,
                groupValue: state.selectedMethodCode,
                onChanged: (_) => _cubit.selectMethod(m.code),
                activeColor: _accent,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => _cubit.selectMethod(m.code),
                  child: Text(
                    _methodTitle(m),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
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
              _cardActions(state, m),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _cubit.selectMethod(m.code),
            child: m.isEcheck ? _buildEcheckCard(m) : _buildCreditCard(m),
          ),
        ],
      ),
    );
  }

  Widget _cardActions(AutoPayMethodsState state, PaymentMethodEntity m) {
    final isDeletingThis = state.deletingMethodCode == m.code;
    if (isDeletingThis) {
      return const Padding(
        padding: EdgeInsets.all(6),
        child: PrimaryCircularLoader(size: 18, strokeWidth: 2),
      );
    }
    final busy = state.isSaving || state.deletingMethodCode != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconAction(
          Icons.edit_outlined,
          const Color(0xFF667EEA),
          busy ? null : () => _openEditMethod(m),
        ),
        _iconAction(
          Icons.delete_outline,
          const Color(0xFFE53E3E),
          busy ? null : () => _confirmAndDelete(m),
        ),
      ],
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey : color),
      ),
    );
  }

  Widget _buildCreditCard(PaymentMethodEntity m) {
    final card = m.card;
    final last4 = card?.last4 ?? m.last4 ?? '••••';
    final type = (card?.cardType ?? m.methodType.apiValue).toUpperCase();
    final gradient = _cardGradient(type);
    final exp = (card?.expireMonth != null && card?.expireYear != null)
        ? '${card!.expireMonth.toString().padLeft(2, '0')}/${card.expireYear}'
        : '--/--';
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480, minHeight: 180),
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
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  type,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
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
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: _detailGroup(
                  'Card Holder',
                  (card?.nameOnCard ?? '').trim().isEmpty
                      ? '—'
                      : card!.nameOnCard!.toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
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
      constraints: const BoxConstraints(maxWidth: 480, minHeight: 180),
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

  String _methodTitle(PaymentMethodEntity m) {
    if (m.label != null && m.label!.trim().isNotEmpty) return m.label!.trim();
    if (m.isEcheck) return 'eCheck account';
    switch (m.methodType) {
      case PaymentMethodType.visa:
        return 'Visa';
      case PaymentMethodType.mast:
        return 'Mastercard';
      case PaymentMethodType.discover:
        return 'Discover';
      default:
        final ct = (m.card?.cardType ?? '').trim();
        return ct.isNotEmpty ? '$ct card' : 'Card';
    }
  }

  String _echeckAccountTypeLabel(String? accountType) {
    final lower = (accountType ?? '').toLowerCase();
    if (lower == 'c' || lower.contains('checking')) return 'Checking';
    if (lower == 's' || lower.contains('saving')) return 'Savings';
    return accountType ?? 'Bank Account';
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        children: [
          Icon(Icons.credit_card_off_outlined, size: 36, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No saved payment methods yet.\nAdd a payment method below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ── Add button ───────────────────────────────────────────────────────────

  Widget _buildAddButton(AutoPayMethodsState state) {
    final canAdd = state.canAddMore && state.hasForteConfig && !state.isSaving;
    return Opacity(
      opacity: canAdd ? 1 : 0.6,
      child: InkWell(
        onTap: canAdd ? _openAddMethod : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F6FD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _autopayTagFg.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline,
                  size: 20, color: _autopayTagFg),
              const SizedBox(width: 8),
              Text(
                state.canAddMore
                    ? 'Add new payment method'
                    : 'Maximum of ${AutoPayMethodsState.maxMethods} methods reached',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: canAdd ? _autopayTagFg : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom bar (Save) ────────────────────────────────────────────────────

  Widget _buildBottomBar(AutoPayMethodsState state) {
    final canSave = state.canSave;
    return Container(
      padding: EdgeInsets.only(
        bottom: (MediaQuery.of(context).padding.bottom > 0)
            ? MediaQuery.of(context).padding.bottom
            : 16,
        left: 16,
        right: 16,
        top: 10,
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
      child: Opacity(
        opacity: canSave ? 1 : 0.5,
        child: InkWell(
          onTap: canSave ? _handleSave : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: state.isSettingPrimary
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save AutoPay Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    final ok = await _cubit.save();
    if (!mounted) return;
    if (ok) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'AutoPay settings saved',
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmAndDelete(PaymentMethodEntity m) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DeleteConfirmationBottomSheet(
        name: _methodTitle(m),
        type: 'payment_method',
        onCancel: () => Navigator.of(sheetCtx).pop(),
        onDelete: () async {
          final ok = await _cubit.deletePaymentMethod(m.code);
          if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
          if (!mounted) return;
          if (ok) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Payment method removed',
              isSuccess: true,
            );
          }
        },
      ),
    );
  }

  /// Opens the Forte tokenization webview and returns the one-time token +
  /// method type, or null if cancelled/failed (showing the error). Shared by
  /// the add and edit flows.
  Future<({String token, PaymentMethodType type})?> _runForteWebview(
    String title, {
    String? defaultMethod,
  }) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AutoPayTokenWebView(
          payload: _cubit.buildWebviewPayload(
            title: title,
            defaultMethod: defaultMethod,
          ),
        ),
      ),
    );
    if (!mounted || result is! Map) return null;

    if (result['success'] != true) {
      final error = result['error'];
      final message = error is Map
          ? (error['response_description'] ??
                  error['response_text'] ??
                  error['error_message'] ??
                  'Unable to process payment method. Please try again.')
              .toString()
          : (error?.toString() ??
              'Unable to process payment method. Please try again.');
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
      );
      return null;
    }

    final tokenData = result['data'];
    final data = tokenData is Map ? tokenData : const {};
    final token =
        (data['onetime_token'] ?? data['onetimeToken'])?.toString() ?? '';
    if (token.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Invalid payment token received from Forte. Please try again.',
        isError: true,
      );
      return null;
    }

    final isEcheck =
        (result['paymentType']?.toString().toLowerCase() ?? '') == 'echeck';
    final type = isEcheck
        ? PaymentMethodType.echeck
        : PaymentMethodTypeX.fromApi(data['card_type']?.toString());
    debugPrint('[AUTOPAY] one_time_token=$token (type=${type.apiValue})');
    return (token: token, type: type);
  }

  /// Adds a new saved payment method via the Forte webview.
  Future<void> _openAddMethod() async {
    final res = await _runForteWebview('Add Payment Method');
    if (res == null || !mounted) return;
    final ok = await _cubit.addPaymentMethodFromToken(
      oneTimeToken: res.token,
      methodType: res.type,
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

  /// Edits a saved method by re-tokenizing (Forte tokens are immutable): the
  /// new details replace the old method, preserving its auto-pay (primary) flag.
  Future<void> _openEditMethod(PaymentMethodEntity m) async {
    final res = await _runForteWebview(
      'Edit Payment Method',
      defaultMethod: m.isEcheck ? 'echeck' : null,
    );
    if (res == null || !mounted) return;
    final ok = await _cubit.replacePaymentMethod(
      oldCode: m.code,
      oldWasPrimary: m.primary,
      oneTimeToken: res.token,
      methodType: res.type,
    );
    if (!mounted) return;
    if (ok) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Payment method updated',
        isSuccess: true,
      );
    }
  }
}
