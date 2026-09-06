import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/theme/fonts.dart';
import 'package:wowcare/presentation/features/billing/model/billing_route_args.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/view_model/discount_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/billing_settings/add_discount_screen.dart';
import 'package:wowcare/presentation/features/billing/model/discount_account_model.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_settings/discount_card.dart';
import 'package:wowcare/presentation/features/billing/view/billing_settings/edit_discount_screen.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class DiscountsSection extends StatefulWidget {
  const DiscountsSection({
    this.onRegisterLoadNextPage,
    this.onLoadMoreNeeded,
    super.key,
  });

  final void Function(VoidCallback)? onRegisterLoadNextPage;
  final VoidCallback? onLoadMoreNeeded;

  @override
  State<DiscountsSection> createState() => _DiscountsSectionState();
}

class _DiscountsSectionState extends State<DiscountsSection> {
  late final DiscountCubit _cubit = GetIt.instance<DiscountCubit>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.loadInitial());
    widget.onRegisterLoadNextPage?.call(() => unawaited(_cubit.loadNextPage()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    _cubit.clearFilters();
  }

  Future<void> _onAdd() async {
    final DiscountAccountModel? created = await context
        .push<DiscountAccountModel>(AddDiscountScreen.routeName);
    if (created == null) return;
    _cubit.addDiscount(created);
  }

  Future<void> _onEdit(DiscountAccountModel discount) async {
    final DiscountAccountModel? updated = await context
        .push<DiscountAccountModel>(
          EditDiscountScreen.routeName,
          extra: EditDiscountArgs(discount: discount),
        );
    if (updated == null) return;
    _cubit.updateDiscount(updated);
  }

  Future<void> _onDeactivate(DiscountAccountModel discount) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.billingCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DeleteConfirmationBottomSheet(
        name: discount.name,
        type: 'ledger_deactivate',
        onCancel: () => Navigator.of(ctx).pop(),
        onDelete: () async {
          final ok = await _cubit.deactivateDiscount(discount.code);
          if (!mounted) return;
          Navigator.of(ctx).pop();
          _showResult(
            ok,
            success: BillingStrings.discountDeactivated,
            fail: BillingStrings.failedToDeactivate,
          );
        },
      ),
    );
  }

  Future<void> _onReactivate(DiscountAccountModel discount) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.billingCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DeleteConfirmationBottomSheet(
        name: discount.name,
        type: 'ledger_reactivate',
        onCancel: () => Navigator.of(ctx).pop(),
        onDelete: () async {
          final ok = await _cubit.reactivateDiscount(discount.code);
          if (!mounted) return;
          Navigator.of(ctx).pop();
          _showResult(
            ok,
            success: BillingStrings.discountReactivated,
            fail: BillingStrings.failedToReactivate,
          );
        },
      ),
    );
  }

  Future<void> _onDelete(DiscountAccountModel discount) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.billingCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DeleteConfirmationBottomSheet(
        name: discount.name,
        type: 'ledger_delete',
        onCancel: () => Navigator.of(ctx).pop(),
        onDelete: () async {
          final ok = await _cubit.deleteDiscount(discount.code);
          if (!mounted) return;
          Navigator.of(ctx).pop();
          _showResult(
            ok,
            success: BillingStrings.discountDeleted,
            fail: BillingStrings.failedToDelete,
          );
        },
      ),
    );
  }

  void _showResult(bool ok, {required String success, required String fail}) {
    if (ok) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: success,
        isSuccess: true,
      );
    } else {
      CoreUtils.showTopSnackBar(context: context, message: fail, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiscountCubit>.value(
      value: _cubit,
      child: BlocBuilder<DiscountCubit, DiscountState>(
        builder: (context, state) {
          // "Show inactive" is additive (both active and inactive show), not
          // a swap to inactive-only — see the onToggle comment below for why
          // a null filter, not 'INACTIVE', is what the toggle actually sets.
          final bool showInactive = state.statusFilter != 'ACTIVE';
          final bool isTablet = ResponsiveHelper(context).isTabletCompact;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title + Add button ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      BillingStrings.discountsConfiguration,
                      style: TextStyle(
                        fontFamily: Fonts.manrope,
                        fontSize: isTablet ? 20.0 : 16.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.billingTextColor,
                      ),
                    ),
                  ),
                  _AddDiscountButton(onTap: _onAdd),
                ],
              ),
              const SizedBox(height: 12),

              // ── Filter card ───────────────────────────────────────
              CustomSectionCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    CustomSearchBar(
                      controller: _searchController,
                      hintText: BillingStrings.searchDiscounts,
                      onChanged: _cubit.setSearchQuery,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CustomClearAllChip(onTap: _clearFilters),
                        const Spacer(),
                        CustomToggle(
                          label: BillingStrings.showInactive,
                          isToggled: showInactive,
                          labelOnLeftSide: true,
                          labelStyle: const TextStyle(
                            fontFamily: Fonts.manrope,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.billingTextColor,
                          ),
                          onToggle: (v) {
                            // "Show inactive" is meant additively — both
                            // active and inactive should show, not swap to
                            // inactive-only — so a null filter (no `status`
                            // query param) fetches every discount instead of
                            // replacing the active list with just inactive
                            // ones and losing the real active totals.
                            _cubit.setStatusFilter(v ? null : 'ACTIVE');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Loading ───────────────────────────────────────────
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: PrimaryCircularLoader()),
                )
              // ── Error ─────────────────────────────────────────────
              else if (state.hasError && state.filteredDiscounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 56,
                        color: AppColors.errorColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        BillingStrings.failedToLoadDiscounts,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 15,
                          color: AppColors.billingTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _cubit.loadInitial,
                        child: const Text(BillingStrings.retry),
                      ),
                    ],
                  ),
                )
              // ── Empty ─────────────────────────────────────────────
              else if (state.filteredDiscounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.discount_outlined,
                        size: 56,
                        color: AppColors.primaryColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        BillingStrings.noDiscountsFound,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 15,
                          color: AppColors.billingTextColor,
                        ),
                      ),
                    ],
                  ),
                )
              // ── List ──────────────────────────────────────────────
              else ...[
                if (widget.onLoadMoreNeeded != null)
                  Builder(
                    builder: (_) {
                      WidgetsBinding.instance.addPostFrameCallback((__) {
                        if (mounted) widget.onLoadMoreNeeded!();
                      });
                      return const SizedBox.shrink();
                    },
                  ),
                ...state.filteredDiscounts.map(
                  (d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: DiscountCard(
                      name: d.name,
                      percentage: d.percentage,
                      totalAmountDiscounted: d.totalAmountDiscounted,
                      isActive: d.isActive,
                      onView: () {},
                      onEdit: d.isActive ? () => _onEdit(d) : null,
                      onDeactivate: d.isActive ? () => _onDeactivate(d) : null,
                      onReactivate: !d.isActive ? () => _onReactivate(d) : null,
                      onDelete: !d.isActive ? () => _onDelete(d) : null,
                    ),
                  ),
                ),

                if (state.isLoadingMore && state.currentPage > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: PrimaryCircularLoader()),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AddDiscountButton extends StatelessWidget {
  const _AddDiscountButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: AppColors.billingCardOnColorText, size: 18),
            SizedBox(width: 4),
            Text(
              BillingStrings.addDiscount,
              style: TextStyle(
                fontFamily: Fonts.manrope,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.billingCardOnColorText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
