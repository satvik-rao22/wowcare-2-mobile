import 'dart:async';

import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/billing_school_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/presentation/features/billing/view_model/auto_pay_methods_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/model/billing_route_args.dart';
import 'package:wowcare/presentation/features/billing/widgets/auto_pay_token_webview.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_elevation.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

class AutoPayPaymentMethodsScreen extends StatefulWidget {
  const AutoPayPaymentMethodsScreen({super.key, this.isPicker = false});

  /// When true the screen acts as a pure "Saved Payment Methods" picker (used by
  /// Pay Now): the auto-pay header/toggle, AutoPay tags and Save action are
  /// hidden, and the bottom button returns the selected method via
  /// `Navigator.pop(method)`.
  final bool isPicker;

  static const String routeName = '/auto-pay-payment-methods';

  @override
  State<AutoPayPaymentMethodsScreen> createState() =>
      _AutoPayPaymentMethodsScreenState();
}

class _AutoPayPaymentMethodsScreenState
    extends State<AutoPayPaymentMethodsScreen> {
  static const Color _accent = AppColors.billingAccentBlue;
  static const Color _autopayTagBg = AppColors.billingAutopayTagBackground;
  static const Color _autopayTagFg = AppColors.billingAutopayTagForeground;

  /// Large base so the looping PageView can scroll both directions endlessly.
  static const int _loopBase = 100000;

  final AutoPayMethodsCubit _cubit = serviceLocator<AutoPayMethodsCubit>();
  // Created once methods load, with an initialPage centered in the loop range
  // so the carousel can scroll both directions endlessly.
  PageController? _pageController;
  int _currentPage = 0;

  /// Bumped to force the auto-pay [CustomToggle] to rebuild and resync with the
  /// committed state — used to undo its optimistic flip when the user backs out
  /// of the "turn off" confirmation.
  int _autopayToggleEpoch = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    _pageController?.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AutoPayMethodsCubit>.value(
      value: _cubit,
      child: BlocConsumer<AutoPayMethodsCubit, AutoPayMethodsState>(
        listenWhen: (prev, curr) =>
            prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
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
            title: widget.isPicker
                ? BillingStrings.savedPaymentMethods
                : 'Auto Payment - ${state.autopayEnabled ? 'Enabled' : 'Disabled'}',
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isPicker) ...[
                    if (state.autoPayBlocked) ...[
                      _buildAutoPayBlockedBanner(),
                      const SizedBox(height: 16),
                    ],
                    _buildAutoPayHeader(state),
                    const Divider(height: 32),
                  ],
                  _buildSectionHeader(state.maxMethods),
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

  /// Intercepts the auto-pay toggle. Enabling is immediate; disabling asks for
  /// confirmation first (the change is still only committed by Save). If the
  /// user backs out, the toggle's optimistic flip is reverted.
  Future<void> _onToggleAutoPay(bool value) async {
    if (value) {
      _cubit.toggleAutoPay(true);
      return;
    }
    var confirmed = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (ctx) => ConfirmationBottomSheet(
        icon: Icons.autorenew,
        title: BillingStrings.turnOffAutoPayment,
        subtitle: BillingStrings.invoicesWillNoLongerBe,
        confirmText: BillingStrings.turnOff,
        cancelText: BillingStrings.keepOn,
        onConfirm: () {
          confirmed = true;
          Navigator.of(ctx).pop();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
    if (!mounted) return;
    if (confirmed) {
      _cubit.toggleAutoPay(false);
    } else {
      // Cancelled or dismissed → undo the toggle's optimistic visual flip.
      setState(() => _autopayToggleEpoch++);
    }
  }

  Widget _buildAutoPayHeader(AutoPayMethodsState state) {
    final enabled = state.autopayEnabled;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.billingInputBorderDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.billingShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _autopayTagBg,
              borderRadius: BorderRadius.circular(12),
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
                    const Flexible(
                      child: Text(
                        BillingStrings.autoPayment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.billingBlackText87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: enabled
                            ? AppColors.billingSuccessBackground
                            : AppColors.billingBadgeInactiveBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        enabled
                            ? BillingStrings.enabled
                            : BillingStrings.disabled,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? AppColors.successColor
                              : AppColors.billingMutedIconColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  BillingStrings.automaticallyPayInvoicesUsing,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.billingBlackText54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CustomToggle(
            key: ValueKey<int>(_autopayToggleEpoch),
            label: '',
            isToggled: enabled,
            onToggle: _onToggleAutoPay,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoPayBlockedBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.billingInfoBannerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.billingInfoBannerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 20, color: AppColors.billingWarningIconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  BillingStrings.autoPayNotAbleToRun,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.billingInfoBannerTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  BillingStrings.autoPayNotAbleToRunBody,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.billingInfoBannerTextColor.withValues(
                      alpha: 0.9,
                    ),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int maxMethods) {
    // Full-size title that wraps to a second line if needed; the "Secure" chip
    // stays full-size, pinned top-right and always visible.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: BillingStrings.savedPaymentMethods),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Tooltip(
                      message:
                          'You can save up to $maxMethods payment methods.',
                      triggerMode: TooltipTriggerMode.tap,
                      showDuration: const Duration(seconds: 3),
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.billingMutedIconColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.billingBlackText87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _secureChip(),
      ],
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.successColor,
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
        height: 248,
        width: double.infinity,
        borderRadius: BorderRadius.circular(20),
      );
    }
    if (!state.hasMethods) return _buildEmptyState();

    final methods = state.methods;
    final count = methods.length;
    // Loop endlessly when there's more than one method.
    final loop = count > 1;
    return Column(
      children: [
        SizedBox(
          height: 248,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: loop ? null : count,
                // With exactly two cards a centered viewport would peek the
                // *same* other card on both sides (3 slots, 2 cards). Aligning
                // to the start (padEnds:false) shows only the next card peeking
                // on one side, so the loop stays a→b→a→b but a reads as a and b
                // as b. 3+ cards keep the centered both-side peek (distinct).
                padEnds: count != 2,
                onPageChanged: (i) => setState(() => _currentPage = i % count),
                itemBuilder: (_, i) =>
                    _buildMethodCard(state, methods[i % count]),
              ),
              if (loop) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _arrowButton(
                    Icons.chevron_left,
                    () => unawaited(
                      _pageController!.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _arrowButton(
                    Icons.chevron_right,
                    () => unawaited(
                      _pageController!.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (loop) _buildDots(count),
        if (state.isSaving) ...[
          const SizedBox(height: 12),
          const Center(
            child: Text(
              BillingStrings.savingYourPaymentMethod,
              style: TextStyle(
                color: AppColors.billingMutedSlateText,
                fontSize: 12,
              ),
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
            color: active ? _accent : AppColors.billingBorderStrong,
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
          color: AppColors.billingCardColor,
          shape: const CircleBorder(),
          elevation: 3,
          shadowColor: AppColors.billingBlackText26,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(icon, size: 22, color: AppColors.billingBlackText54),
            ),
          ),
        ),
      ),
    );
  }

  void _maybePositionToPrimary(AutoPayMethodsState state) {
    if (_pageController != null || state.isLoading || !state.hasMethods) return;
    final methods = state.methods;
    final idx = methods.indexWhere((m) => m.code == state.selectedMethodCode);
    final target = idx >= 0 ? idx : 0;
    _currentPage = target;
    // For >1 methods start deep in the loop range so both directions scroll
    // forever; for a single method just start at it (no loop).
    final initialPage = methods.length > 1
        ? _loopBase - (_loopBase % methods.length) + target
        : target;
    _pageController = PageController(
      viewportFraction: 0.88,
      initialPage: initialPage,
    );
  }

  // ── Method card (rich visual) ────────────────────────────────────────────

  Widget _buildMethodCard(AutoPayMethodsState state, PaymentMethodEntity m) {
    final selected = state.selectedMethodCode == m.code;
    // The school can stop accepting a method type after it was saved — such
    // a method can't be picked (for AutoPay or Pay Now) until removed or the
    // school re-enables the type, so it's greyed out and non-selectable
    // rather than silently letting the user choose something that won't work.
    final disabled = !m.acceptedByPolicy;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.billingSelectedCardBackground
            : AppColors.billingCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppColors.successColor
              : AppColors.billingInputBorderDefault,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withValues(
              alpha: selected ? 0.08 : 0.04,
            ),
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
                onChanged: disabled ? null : (_) => _cubit.selectMethod(m.code),
                activeColor: _accent,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              if (m.autopay)
                _tag(BillingStrings.autoPay, _autopayTagBg, _autopayTagFg),
              if (m.primary) ...[
                if (m.autopay) const SizedBox(width: 6),
                _tag(
                  BillingStrings.primary,
                  AppColors.billingSuccessBackground,
                  AppColors.successColor,
                ),
              ],
              if (disabled) ...[
                if (m.autopay || m.primary) const SizedBox(width: 6),
                _tag(BillingStrings.notAccepted,
                    AppColors.billingBadgeInactiveBackground,
                    AppColors.billingMutedIconColor),
              ],
              const Spacer(),
              _cardActions(state, m),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GestureDetector(
              onTap: disabled ? null : () => _cubit.selectMethod(m.code),
              child: m.isEcheck ? _buildEcheckCard(m) : _buildCreditCard(m),
            ),
          ),
        ],
      ),
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
          AppColors.billingEditActionColor,
          busy ? null : () => _openEditMethod(m),
        ),
        // A primary method can't be deleted — pick another primary first.
        if (!m.primary)
          _iconAction(
            Icons.delete_outline,
            AppColors.billingDeleteActionColor,
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
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.billingMutedIconColor : color,
        ),
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildCreditCard(PaymentMethodEntity m) {
    final card = m.card;
    final last4 = card?.last4 ?? m.last4 ?? '••••';
    final type = (card?.cardType ?? m.methodType.apiValue).toUpperCase();
    final Color face = _cardFace(type);
    final exp = (card?.expireMonth != null && card?.expireYear != null)
        ? '${card!.expireMonth.toString().padLeft(2, '0')}/${card.expireYear}'
        : '--/--';
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(20),
      decoration: AppSurfaces.impact().copyWith(color: face),
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
                    color: AppColors.billingCardOnColorText,
                    fontWeight: FontWeight.w600,
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
                    color: AppColors.billingCardOnColorText,
                    letterSpacing: 2,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  last4,
                  style: const TextStyle(
                    color: AppColors.billingCardOnColorText,
                    letterSpacing: 2,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                  BillingStrings.cardHolder,
                  (card?.nameOnCard ?? '').trim().isEmpty
                      ? '—'
                      : card!.nameOnCard!.toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              _detailGroup(BillingStrings.expires, exp),
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
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.billingEcheckCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.billingEcheckCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                BillingStrings.echeck,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.billingEcheckTitleColor,
                ),
              ),
              Text(
                _echeckAccountTypeLabel(e?.accountType),
                style: const TextStyle(
                  color: AppColors.billingBlackText54,
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
                  BillingStrings.accountHolderName,
                  e?.accountHolder ?? '—',
                  isDark: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _detailGroup(
                  BillingStrings.routingNumber,
                  e?.routingNumber ?? '—',
                  isDark: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailGroup(
            BillingStrings.lastFour,
            e?.last4 ?? m.last4 ?? '—',
            isDark: false,
          ),
        ],
      ),
    );
  }

  String _methodTitle(PaymentMethodEntity m) {
    if (m.label != null && m.label!.trim().isNotEmpty) return m.label!.trim();
    if (m.isEcheck) return BillingStrings.echeckAccount;
    switch (m.methodType) {
      case PaymentMethodType.visa:
        return BillingStrings.visa;
      case PaymentMethodType.mast:
        return BillingStrings.mastercard;
      case PaymentMethodType.discover:
        return BillingStrings.discover;
      default:
        final ct = (m.card?.cardType ?? '').trim();
        return ct.isNotEmpty ? '$ct card' : BillingStrings.card;
    }
  }

  String _echeckAccountTypeLabel(String? accountType) {
    final lower = (accountType ?? '').toLowerCase();
    if (lower == 'c' || lower.contains('checking'))
      return BillingStrings.checking;
    if (lower == 's' || lower.contains('saving')) return BillingStrings.savings;
    return accountType ?? BillingStrings.bankAccount;
  }

  /// The face of a stored card. All four are the navy impact face: the brand
  /// is carried by the card's own logo and label, not by tinting the whole
  /// card, and four saturated washes in one list read as decoration.
  Color _cardFace(String cardType) {
    final type = cardType.toLowerCase();
    if (type.contains('visa')) return AppColors.billingVisaCardFace;
    if (type.contains('mast') || type.contains('master')) {
      return AppColors.billingMastercardCardFace;
    }
    if (type.contains('disc')) return AppColors.billingDiscoverCardFace;
    return AppColors.billingGenericCardFace;
  }

  Widget _buildChip() {
    return Container(
      width: 40,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColors.billingCardChipColor,
        boxShadow: AppElevation.card,
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
            color: isDark
                ? AppColors.billingDetailLabelOnDark
                : AppColors.billingBlackText54,
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
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.billingCardOnColorText
                : AppColors.billingBlackText87,
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
        color: AppColors.billingSurfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.billingBorderStrong),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.credit_card_off_outlined,
            size: 36,
            color: AppColors.billingMutedIconColor,
          ),
          SizedBox(height: 8),
          Text(
            BillingStrings.noSavedPaymentMethodsYet,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.billingBlackText54),
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
            color: AppColors.billingAddMethodButtonBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _autopayTagFg.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 20,
                color: _autopayTagFg,
              ),
              const SizedBox(width: 8),
              Text(
                state.canAddMore
                    ? BillingStrings.addNewPaymentMethod
                    : 'Maximum of ${state.maxMethods} methods reached',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: canAdd
                      ? _autopayTagFg
                      : AppColors.billingMutedIconColor,
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
    final canAct = widget.isPicker
        ? state.selectedMethodCode != null && !state.isSaving
        : state.canSave;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: canAct ? 1 : 0.5,
          child: InkWell(
            onTap: canAct
                ? (widget.isPicker ? _handleContinue : _handleSave)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: SkeuKeyBox(
              variant: KeyVariant.primary,
              radius: 16,
              width: double.infinity,
              height: 54,
              child: Center(
                child: state.isSettingPrimary
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.billingCardOnColorText,
                          ),
                        ),
                      )
                    : Text(
                        widget.isPicker
                            ? BillingStrings.continueLabel
                            : BillingStrings.save,
                        style: const TextStyle(
                          color: AppColors.billingCardOnColorText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 14,
              color: AppColors.billingMutedIconColor,
            ),
            const SizedBox(width: 6),
            Text(
              BillingStrings.yourPaymentInformationIsSecure,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.billingCaptionTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Picker mode: return the chosen method to the caller (Pay Now).
  void _handleContinue() {
    final code = _cubit.state.selectedMethodCode;
    if (code == null) return;
    final method = _cubit.state.methods.firstWhere(
      (m) => m.code == code,
      orElse: () => _cubit.state.methods.first,
    );
    Navigator.of(context).pop(method);
  }

  Future<void> _handleSave() async {
    final ok = await _cubit.save();
    if (!mounted) return;
    if (ok) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: BillingStrings.autoPaySettingsSaved,
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _confirmAndDelete(PaymentMethodEntity m) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
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
              message: BillingStrings.paymentMethodRemoved,
              isSuccess: true,
            );
          }
        },
      ),
    );
  }

  /// Adds a new saved payment method via the Forte webview (which now collects
  /// the account-holder name and the Make-Primary / Use-for-AutoPay toggles).
  Future<void> _openAddMethod() async {
    // One event per WebView session, from what it pops with.
    final result = await AppEvents.track(
      AppEvent.billingCardTokenize,
      () => context.push<dynamic>(
        AutoPayTokenWebView.routeName,
        extra: AutoPayTokenWebViewArgs(
          payload: _cubit.buildWebviewPayload(
            title: BillingStrings.addPaymentMethod,
          ),
        ),
      ),
      failureOf: cardTokenizeFailureOf,
    );
    if (!mounted || result is! Map) return;

    if (result['success'] != true) {
      final error = result['error'];
      final message = error is Map
          ? (error['response_description'] ??
                    error['response_text'] ??
                    error['error_message'] ??
                    BillingStrings.unableToAddPaymentMethod)
                .toString()
          : (error?.toString() ?? BillingStrings.unableToAddPaymentMethod);
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
      );
      return;
    }

    final tokenData = result['data'];
    final data = tokenData is Map ? tokenData : const {};
    final token =
        (data['onetime_token'] ?? data['onetimeToken'])?.toString() ?? '';
    if (token.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: BillingStrings.invalidPaymentTokenReceived,
        isError: true,
      );
      return;
    }

    final isEcheck =
        (result['paymentType']?.toString().toLowerCase() ?? '') == 'echeck';
    final type = isEcheck
        ? PaymentMethodType.echeck
        : PaymentMethodTypeX.fromApi(data['card_type']?.toString());
    // Never log the one-time payment token — only the non-sensitive shape.
    AppLogger.d(
      '[AUTOPAY] tokenization result (type=${type.apiValue}, tokenPresent=${token.isNotEmpty})',
    );

    final ok = await _cubit.addPaymentMethodFromToken(
      oneTimeToken: token,
      methodType: type,
      accountHolder: result['accountHolder']?.toString(),
      makePrimary: result['makePrimary'] == true,
      makeAutopay: result['makeAutopay'] == true,
    );
    if (!mounted) return;
    if (ok) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: BillingStrings.paymentMethodAdded,
        isSuccess: true,
      );
    }
  }

  /// Edits a saved method's editable fields via the PUT endpoint. The tokenized
  /// card/account number itself can't change.
  Future<void> _openEditMethod(PaymentMethodEntity m) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (_) => _EditMethodSheet(method: m, cubit: _cubit),
    );
    if (!mounted || saved != true) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: BillingStrings.paymentMethodUpdated,
      isSuccess: true,
    );
  }
}

/// The [AppEvent.billingCardTokenize] failure for what the card WebView popped
/// with, or null when a one-time token came back. Reads only the shape of the
/// result, mirroring the checks in `_openAddMethod`; the token is never logged.
@visibleForTesting
EventFailure? cardTokenizeFailureOf(Object? result) {
  // The close button and the back button pop with no result.
  if (result == null) return EventFailure.cancelled;
  if (result is! Map) return EventFailure.unknown;
  if (result['success'] != true) {
    final error = result['error'];
    // The form's own check that the card matches the card type picked.
    if (error is Map && error['event'] == 'card_type_mismatch') {
      return EventFailure.validation;
    }
    // The Forte script failed to load (assets/forte_auto_pay.html).
    if (error == 'Unable to load Forte payment library') {
      return EventFailure.network;
    }
    return EventFailure.unknown;
  }
  final data = result['data'];
  final token = data is Map
      ? (data['onetime_token'] ?? data['onetimeToken'])?.toString() ?? ''
      : '';
  return token.isEmpty ? EventFailure.unknown : null;
}

/// UPPERCASE letters only, max 4 words, a single space between words and no
/// leading space — shared by the account-holder fields.
List<TextInputFormatter> _holderFormatters() => [
  FilteringTextInputFormatter.allow(RegExp('[A-Za-z ]')),
  TextInputFormatter.withFunction((old, value) {
    var v = value.text
        .toUpperCase()
        .replaceAll(RegExp(' {2,}'), ' ') // single space between words
        .replaceFirst(RegExp(r'^\s+'), ''); // no leading space
    final parts = v.split(' ');
    if (parts.length > 4) v = parts.sublist(0, 4).join(' '); // max 4 words
    return value.copyWith(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
  }),
];

/// Bottom-sheet editor for a saved method: editable fields per type (card:
/// name + expiry; eCheck: holder, routing, type) plus Make Primary / Use for
/// AutoPay toggles. Commits via [AutoPayMethodsCubit.updatePaymentMethod].
class _EditMethodSheet extends StatefulWidget {
  const _EditMethodSheet({required this.method, required this.cubit});

  final PaymentMethodEntity method;
  final AutoPayMethodsCubit cubit;

  @override
  State<_EditMethodSheet> createState() => _EditMethodSheetState();
}

class _EditMethodSheetState extends State<_EditMethodSheet> {
  static const Color _primary = AppColors.billingTextColor;

  late final TextEditingController _holder;
  late final TextEditingController _routing;
  String _expMonth = '';
  String _expYear = '';
  String _accountType = 'checking';
  late bool _makePrimary;
  late bool _makeAutopay;

  bool get _isEcheck => widget.method.isEcheck;

  @override
  void initState() {
    super.initState();
    final m = widget.method;
    _holder = TextEditingController(
      text:
          (_isEcheck ? m.echeck?.accountHolder : m.card?.nameOnCard ?? '')
              ?.toUpperCase() ??
          '',
    );
    _routing = TextEditingController(text: m.echeck?.routingNumber ?? '');
    if (m.card?.expireMonth != null) {
      _expMonth = m.card!.expireMonth.toString().padLeft(2, '0');
    }
    if (m.card?.expireYear != null) _expYear = m.card!.expireYear.toString();
    _accountType = _normAccountType(m.echeck?.accountType);
    _makePrimary = m.primary;
    _makeAutopay = m.autopay;
  }

  @override
  void dispose() {
    _holder.dispose();
    _routing.dispose();
    super.dispose();
  }

  String _normAccountType(String? t) {
    final l = (t ?? '').toLowerCase();
    if (l == 's' || l.contains('saving')) return 'savings';
    return 'checking';
  }

  Future<void> _save() async {
    final ok = _isEcheck
        ? await widget.cubit.updatePaymentMethod(
            method: widget.method,
            accountHolder: _holder.text,
            routingNumber: _routing.text,
            accountType: _accountType,
            makePrimary: _makePrimary,
            makeAutopay: _makeAutopay,
          )
        : await widget.cubit.updatePaymentMethod(
            method: widget.method,
            nameOnCard: _holder.text,
            expireMonth: int.tryParse(_expMonth),
            expireYear: int.tryParse(_expYear),
            makePrimary: _makePrimary,
            makeAutopay: _makeAutopay,
          );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final months = List<String>.generate(12, (i) => '${i + 1}'.padLeft(2, '0'));
    final currentYear = billingSchoolCurrentYear();
    final years = List<String>.generate(20, (i) => '${currentYear + i}');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.billingCardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.billingBorderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                BillingStrings.editPaymentMethod,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 16),
              _label(BillingStrings.accountHolderName),
              _field(
                controller: _holder,
                hint: BillingStrings.enterAccountHolderName,
                formatters: _holderFormatters(),
                capsAll: true,
              ),
              if (_isEcheck) ...[
                const SizedBox(height: 14),
                _label(BillingStrings.routingNumber),
                _field(
                  controller: _routing,
                  hint: BillingStrings.enterRoutingNumber,
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                ),
                const SizedBox(height: 14),
                CustomDropdown(
                  label: BillingStrings.accountType,
                  hintText: BillingStrings.selectAccountType,
                  items: const [
                    BillingStrings.checking,
                    BillingStrings.savings,
                  ],
                  selectedItem: _accountType == 'savings'
                      ? BillingStrings.savings
                      : BillingStrings.checking,
                  labelStyle: _ddLabel,
                  showAsterisk: false,
                  labelBottomSpacing: 6,
                  fieldHeight: 52,
                  onSelect: (v) {
                    if (v == null) return;
                    setState(
                      () => _accountType = v == 'Savings'
                          ? 'savings'
                          : 'checking',
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomDropdown(
                        label: BillingStrings.expiryMonth,
                        hintText: 'MM',
                        items: months,
                        selectedItem: months.contains(_expMonth)
                            ? _expMonth
                            : null,
                        labelStyle: _ddLabel,
                        showAsterisk: false,
                        labelBottomSpacing: 6,
                        fieldHeight: 52,
                        onSelect: (v) {
                          if (v != null) setState(() => _expMonth = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomDropdown(
                        label: BillingStrings.expiryYear,
                        hintText: 'YYYY',
                        items: years,
                        selectedItem: years.contains(_expYear)
                            ? _expYear
                            : null,
                        labelStyle: _ddLabel,
                        showAsterisk: false,
                        labelBottomSpacing: 6,
                        fieldHeight: 52,
                        onSelect: (v) {
                          if (v != null) setState(() => _expYear = v);
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _toggleRow(
                title: BillingStrings.makePrimary,
                subtitle: BillingStrings.useThisAsTheDefault,
                value: _makePrimary,
                // Already primary → can't be unset here; tapping explains how to
                // change it (promote another card) instead of toggling.
                lockedMessage: widget.method.primary
                    ? BillingStrings.thisCardIsAlreadyPrimary
                    : null,
                onChanged: (v) => setState(() => _makePrimary = v),
              ),
              const SizedBox(height: 10),
              _toggleRow(
                title: BillingStrings.useForAutoPay,
                subtitle: BillingStrings.automaticallyDeductOutstandingBalances,
                value: _makeAutopay,
                // Already the AutoPay card → no per-method unset; tapping explains
                // to use another card for AutoPay.
                lockedMessage: widget.method.autopay
                    ? BillingStrings.thisCardIsAlreadyUsed
                    : null,
                onChanged: (v) => setState(() => _makeAutopay = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: AppSurfaces.key(KeyVariant.primary, radius: 14),
                  child: BlocBuilder<AutoPayMethodsCubit, AutoPayMethodsState>(
                    bloc: widget.cubit,
                    buildWhen: (prev, curr) => prev.isSaving != curr.isSaving,
                    builder: (context, state) {
                      final saving = state.isSaving;
                      return TextButton(
                        onPressed: saving ? null : _save,
                        child: saving
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
                            : const Text(
                                BillingStrings.saveChanges,
                                style: TextStyle(
                                  color: AppColors.billingCardOnColorText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Label style shared by the CustomDropdowns (matches the Add Staff form).
  static const TextStyle _ddLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: _primary,
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: _primary,
      ),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    bool capsAll = false,
  }) {
    return Container(
      decoration: AppSurfaces.field(radius: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        textCapitalization: capsAll
            ? TextCapitalization.characters
            : TextCapitalization.none,
        style: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _primary,
          height: 19 / 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.billingMutedIconColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? lockedMessage,
  }) {
    final locked = lockedMessage != null;
    Widget toggle = CustomToggle(
      label: '',
      isToggled: value,
      onToggle: onChanged,
    );
    if (locked) {
      // Keep the toggle looking normal, but swallow the tap and show a hint
      // instead of flipping (there is no per-method "unset" endpoint).
      toggle = Stack(
        children: [
          IgnorePointer(child: toggle),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => CoreUtils.showTopSnackBar(
                context: context,
                message: lockedMessage,
                isWarning: true,
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.billingBorderStrong),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.billingCaptionTextColor,
                  ),
                ),
              ],
            ),
          ),
          toggle,
        ],
      ),
    );
  }
}
