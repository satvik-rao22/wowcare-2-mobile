import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:wowcare/app/di/di.dart';
import '../../../../app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/pay_now_cubit.dart';
import 'package:wowcare/presentation/features/billing/cubit/pay_now_authorize_cubit.dart';
import 'package:wowcare/presentation/features/billing/cubit/payment_settings_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/auto_pay_payment_methods_screen.dart';
import 'package:wowcare/presentation/features/billing/view/pay_now_authorize_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Pay Now — step 1: choose how much to pay (full family balance or a custom
/// per-owner allocation). Continues to the saved-method picker.
class PayNowAmountScreen extends StatefulWidget {
  const PayNowAmountScreen({super.key});

  static const String routeName = '/pay-now-amount';

  @override
  State<PayNowAmountScreen> createState() => _PayNowAmountScreenState();
}

class _PayNowAmountScreenState extends State<PayNowAmountScreen> {
  static const Color _primary = Color(0xFF573353);
  static const Color _accent = Color(0xFF6F8CFF);

  final PayNowCubit _cubit = serviceLocator<PayNowCubit>();
  final PaymentSettingsCubit _settingsCubit =
      serviceLocator<PaymentSettingsCubit>();
  final TextEditingController _currentController = TextEditingController();
  final Map<String, TextEditingController> _customControllers = {};
  bool _seededCurrent = false;

  /// Kicked off on open so the school payment settings are ready by the time the
  /// review screen is reached — avoids the convenience-fee row flickering.
  /// Nullable (not `late`) so a hot reload, which re-runs build but not
  /// initState, can't trip a LateInitializationError.
  Future<void>? _settingsFuture;

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.load());
    _settingsFuture = _settingsCubit.load();
  }

  @override
  void dispose() {
    _currentController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    unawaited(_cubit.close());
    unawaited(_settingsCubit.close());
    super.dispose();
  }

  TextEditingController _controllerFor(String ownerCode) =>
      _customControllers.putIfAbsent(ownerCode, () => TextEditingController());

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PayNowCubit>.value(
      value: _cubit,
      child: BlocConsumer<PayNowCubit, PayNowState>(
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
          // Seed the family-balance field once after load.
          if (!state.isLoading && !_seededCurrent) {
            _seededCurrent = true;
            _currentController.text = state.currentAmount > 0
                ? _money(state.currentAmount)
                : '';
          }
          return StaffFormLayout(
            title: 'Pay Now',
            bottomBar: _buildBottomBar(state),
            child: state.isLoading
                ? _buildLoading()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Amount',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCurrentOption(state),
                        const SizedBox(height: 16),
                        _buildCustomOption(state),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ShimmerLoader(
        height: 22,
        width: 160,
        borderRadius: BorderRadius.circular(6),
      ),
      const SizedBox(height: 16),
      ShimmerLoader(
        height: 56,
        width: double.infinity,
        borderRadius: BorderRadius.circular(10),
      ),
      const SizedBox(height: 16),
      ShimmerLoader(
        height: 56,
        width: double.infinity,
        borderRadius: BorderRadius.circular(10),
      ),
    ],
  );

  Widget _buildCurrentOption(PayNowState state) {
    final selected = state.mode == PayNowAmountMode.currentOutstanding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _cubit.setMode(PayNowAmountMode.currentOutstanding),
          child: Row(
            children: [
              Radio<PayNowAmountMode>(
                value: PayNowAmountMode.currentOutstanding,
                groupValue: state.mode,
                activeColor: _accent,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) =>
                    _cubit.setMode(PayNowAmountMode.currentOutstanding),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Current Outstanding (Unpaid Balance)',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: selected ? 1 : 0.5,
          child: IgnorePointer(
            ignoring: !selected,
            child: _amountField(
              controller: _currentController,
              onChanged: _cubit.setCurrentAmount,
              hasError: selected && state.currentExceedsUnpaid,
            ),
          ),
        ),
        if (selected && state.currentExceedsUnpaid)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              '*Amount exceeds unpaid balance (\$${_money(state.unpaid)}).',
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomOption(PayNowState state) {
    final selected = state.mode == PayNowAmountMode.custom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _cubit.setMode(PayNowAmountMode.custom),
          child: Row(
            children: [
              Radio<PayNowAmountMode>(
                value: PayNowAmountMode.custom,
                groupValue: state.mode,
                activeColor: _accent,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) => _cubit.setMode(PayNowAmountMode.custom),
              ),
              const SizedBox(width: 8),
              const Text(
                'Custom Amount',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
        if (selected) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey.shade200),
            ),
            child: Column(
              children: [
                for (final s in state.students) ...[
                  _customRow(state, s),
                  const SizedBox(height: 12),
                ],
                const Divider(height: 8),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Payment Amount:',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                    Text(
                      '\$${_money(state.customTotal)}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _customRow(PayNowState state, FamilyLedgerPersonEntity student) {
    final over = state.customExceedsOutstandingFor(student);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: over ? AppColors.errorColor : AppColors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: student.fullName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                TextSpan(
                  text: '  (Outstanding: \$${_money(student.outstanding)})',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _amountField(
            controller: _controllerFor(student.code),
            onChanged: (v) => _cubit.setCustomAmount(student.code, v),
            hasError: over,
          ),
          if (over)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 2),
              child: Text(
                '*Amount exceeds outstanding.',
                style: TextStyle(color: AppColors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _amountField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    bool hasError = false,
  }) {
    final responsive = ResponsiveHelper(context);
    // Match the input styling used across the staff forms (add_staff_screen):
    // Manrope, primary text color, soft border, InputBorder.none inside a
    // bordered container.
    final textStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: responsive.inputFontSize,
      fontWeight: FontWeight.w600,
      color: const Color(0xff573353),
      height: 19 / 14,
    );
    return Container(
      constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: hasError ? AppColors.errorColor : const Color(0x66573353),
        ),
        borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        onChanged: onChanged,
        style: textStyle,
        decoration: InputDecoration(
          prefixText: '\$ ',
          prefixStyle: textStyle,
          hintText: '0',
          hintStyle: textStyle.copyWith(color: AppColors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive.isTablet ? 16.0 : 12.0,
            vertical: responsive.isTablet ? 16.0 : 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(PayNowState state) {
    final canConfirm = state.canConfirm;
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
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Opacity(
        opacity: canConfirm ? 1 : 0.5,
        child: InkWell(
          onTap: canConfirm ? () => unawaited(_confirm()) : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: AppColors.white,
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

  Future<void> _confirm() async {
    final state = _cubit.state;
    if (!state.canConfirm) return;

    // The guardian has one family, so the charge is applied to that family. The
    // amount is the unpaid balance (Current Outstanding) or the sum the parent
    // allocated across children (Custom). One MOBILE-<uuid> idempotency key is
    // minted NOW (step 2) and fixed before the final Pay tap, so retries reuse
    // it and the backend dedupes double-submits / network retries.
    final double total = state.amount;
    // Idempotency key: MOBILE-<uuid>-<guardianCode>. The uuid makes it unique
    // per attempt; the guardian code is appended at the end.
    final String guardian = state.guardianCode.trim();
    final String idempotencyKey =
        'MOBILE-${const Uuid().v4()}'
        '${guardian.isNotEmpty ? '-$guardian' : ''}';
    final charge = PayNowCharge(
      ownerType: state.ownerType,
      ownerCode: state.ownerCode,
      familyName: state.ledger?.familyName ?? '',
      amount: total,
      idempotencyKey: idempotencyKey,
      // Custom mode splits the amount per child; Current Outstanding leaves
      // allocations empty so the backend applies it family-wide (oldest first).
      allocations: state.allocations,
    );

    // Step 2: the Saved Payment Methods picker (AutoPay UI without auto-pay).
    final method = await Navigator.of(context).push<PaymentMethodEntity>(
      MaterialPageRoute(
        builder: (_) => const AutoPayPaymentMethodsScreen(isPicker: true),
      ),
    );
    if (!mounted || method == null) return;
    // Ensure the school payment settings have resolved before showing the
    // review screen, so the convenience-fee row is correct on the first frame
    // (no show-then-hide flicker). The fetch started on screen open, so this is
    // usually already done by now (??= guards a hot-reloaded state where
    // initState didn't run).
    await (_settingsFuture ??= _settingsCubit.load());
    if (!mounted) return;
    // Step 3: review + authorize (real charge via the payment gateway).
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PayNowAuthorizeScreen(
          method: method,
          amount: total,
          charges: <PayNowCharge>[charge],
          settings: _settingsCubit.state.settings,
        ),
      ),
    );
    // A payment was made — dismiss the entry screen and signal the billing
    // screen to reload its ledger so the new transaction appears.
    if (paid == true && mounted) Navigator.of(context).pop(true);
  }

  String _money(double v) => v.toStringAsFixed(2);
}
