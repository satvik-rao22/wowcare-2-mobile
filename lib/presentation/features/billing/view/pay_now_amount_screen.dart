import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/entities/family_summary_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/pay_now_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/auto_pay_payment_methods_screen.dart';
import 'package:wowcare/presentation/features/billing/view/pay_now_authorize_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';

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
  final TextEditingController _currentController = TextEditingController();
  final Map<String, TextEditingController> _customControllers = {};
  bool _seededCurrent = false;

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    _currentController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    unawaited(_cubit.close());
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
            _currentController.text =
                state.currentAmount > 0 ? _money(state.currentAmount) : '';
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
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
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
          ShimmerLoader(height: 22, width: 160, borderRadius: BorderRadius.circular(6)),
          const SizedBox(height: 16),
          ShimmerLoader(height: 56, width: double.infinity, borderRadius: BorderRadius.circular(10)),
          const SizedBox(height: 16),
          ShimmerLoader(height: 56, width: double.infinity, borderRadius: BorderRadius.circular(10)),
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
                  'Current Outstanding (Family Balance)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
            ),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                for (final f in state.families) ...[
                  _customRow(f),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    Text(
                      '\$${_money(state.customTotal)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
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

  Widget _customRow(FamilySummaryEntity family) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: family.familyName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                TextSpan(
                  text: '  (Outstanding: \$${_money(family.openBalance)})',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _amountField(
            controller: _controllerFor(family.ownerCode),
            onChanged: (v) => _cubit.setCustomAmount(family.ownerCode, v),
          ),
        ],
      ),
    );
  }

  Widget _amountField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixText: '\$ ',
        hintText: '0',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
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
        color: Colors.white,
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

  Future<void> _confirm() async {
    if (!_cubit.state.canConfirm) return;
    final amount = _cubit.state.amount;
    // Step 2: the Saved Payment Methods picker (AutoPay UI without auto-pay).
    final method = await Navigator.of(context).push<PaymentMethodEntity>(
      MaterialPageRoute(
        builder: (_) => const AutoPayPaymentMethodsScreen(isPicker: true),
      ),
    );
    if (!mounted || method == null) return;
    // Step 3: our mocked authorize screen.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PayNowAuthorizeScreen(method: method, amount: amount),
      ),
    );
  }

  String _money(double v) => v.toStringAsFixed(2);
}
