import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/cubit/general_ledger_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/general_ledger/ledger_detail_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/ledger_card.dart';
import 'package:wowcare/presentation/features/billing/view/general_ledger/edit_ledger_screen.dart';
import 'package:wowcare/presentation/features/billing/model/ledger_account_model.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class GeneralLedgerSection extends StatefulWidget {
  const GeneralLedgerSection({
    this.ledgerCreationNotifier,
    this.onRegisterRefresh,
    this.onRegisterLoadNextPage,
    this.onLoadMoreNeeded,
    super.key,
  });

  final ValueNotifier<LedgerAccountModel?>? ledgerCreationNotifier;
  final void Function(Future<void> Function())? onRegisterRefresh;
  final void Function(VoidCallback)? onRegisterLoadNextPage;
  final VoidCallback? onLoadMoreNeeded;

  @override
  State<GeneralLedgerSection> createState() => _GeneralLedgerSectionState();
}

class _GeneralLedgerSectionState extends State<GeneralLedgerSection> {
  late final GeneralLedgerCubit _cubit = GetIt.instance<GeneralLedgerCubit>();
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'Income',
    'Expense',
    'Asset',
    'Liability',
    'Equity',
  ];

  String? get _selectedCategory => _cubit.state.selectedCategory;

  @override
  void initState() {
    super.initState();
    unawaited(_cubit.loadInitial());
    widget.ledgerCreationNotifier?.addListener(_handleLedgerCreated);
    widget.onRegisterRefresh?.call(_cubit.loadInitial);
    widget.onRegisterLoadNextPage
        ?.call(() => unawaited(_cubit.loadNextPage()));
  }

  @override
  void didUpdateWidget(covariant GeneralLedgerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ledgerCreationNotifier != widget.ledgerCreationNotifier) {
      oldWidget.ledgerCreationNotifier?.removeListener(_handleLedgerCreated);
      widget.ledgerCreationNotifier?.addListener(_handleLedgerCreated);
    }
  }

  void _clearFilters() {
    _searchController.clear();
    _cubit.clearFilters();
  }

  void _handleLedgerCreated() {
    final LedgerAccountModel? newLedger = widget.ledgerCreationNotifier?.value;
    if (newLedger == null) return;
    _cubit.addLedger(newLedger);
    widget.ledgerCreationNotifier?.value = null;
  }

  void _onView(LedgerAccountModel ledger) {
    unawaited(Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LedgerDetailScreen(ledger: ledger),
      ),
    ));
  }

  Future<void> _onEdit(LedgerAccountModel ledger) async {
    final LedgerAccountModel? updated = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditLedgerScreen(ledger: ledger)),
    );
    if (updated == null) return;
    _cubit.updateLedger(updated);
  }

  Future<void> _onDeactivate(LedgerAccountModel ledger) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DeleteConfirmationBottomSheet(
        name: ledger.name,
        type: 'ledger_deactivate',
        onCancel: () => Navigator.of(ctx).pop(),
        onDelete: () async {
          final ok = await _cubit.deactivateLedger(ledger.id);
          if (!mounted) return;
          Navigator.of(ctx).pop();
          _showResult(ok,
              success: 'Ledger deactivated.', fail: 'Failed to deactivate.');
        },
      ),
    );
  }

  Future<void> _onReactivate(LedgerAccountModel ledger) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DeleteConfirmationBottomSheet(
        name: ledger.name,
        type: 'ledger_reactivate',
        onCancel: () => Navigator.of(ctx).pop(),
        onDelete: () async {
          final ok = await _cubit.reactivateLedger(ledger.id);
          if (!mounted) return;
          Navigator.of(ctx).pop();
          _showResult(ok,
              success: 'Ledger reactivated.', fail: 'Failed to reactivate.');
        },
      ),
    );
  }

  Future<void> _onDelete(LedgerAccountModel ledger) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DeleteConfirmationBottomSheet(
        name: ledger.name,
        type: 'ledger_delete',
        onCancel: () => Navigator.of(ctx).pop(),
        onDelete: () async {
          final ok = await _cubit.deleteLedger(ledger.id);
          if (!mounted) return;
          Navigator.of(ctx).pop();
          _showResult(ok,
              success: 'Ledger deleted.', fail: 'Failed to delete.');
        },
      ),
    );
  }

  void _showResult(bool ok, {required String success, required String fail}) {
    if (ok) {
      CoreUtils.showTopSnackBar(
          context: context, message: success, isSuccess: true);
    } else {
      CoreUtils.showTopSnackBar(
          context: context, message: fail, isError: true);
    }
  }

  @override
  void dispose() {
    widget.ledgerCreationNotifier?.removeListener(_handleLedgerCreated);
    _searchController.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GeneralLedgerCubit>.value(
      value: _cubit,
      child: BlocBuilder<GeneralLedgerCubit, GeneralLedgerState>(
        builder: (context, state) {
          final bool showInactive = state.statusFilter == 'INACTIVE';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Filter card ─────────────────────────────────────────
              CustomSectionCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomSearchBar(
                            controller: _searchController,
                            hintText: 'Search Ledger',
                            onChanged: (q) {
                              _cubit.setSearchQuery(q);
                              _cubit.applySearch();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        CustomClearAllChip(onTap: _clearFilters),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Category dropdown + Show inactive toggle — same row
                    Row(
                      children: [
                        Expanded(
                          child: CustomDropdown(
                            hintText: 'All Categories',
                            items: _categories,
                            selectedItem: _selectedCategory,
                            onSelect: (value) {
                              _cubit.setCategory(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Show inactive',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff573353),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomToggle(
                              label: '',
                              isToggled: showInactive,
                              onToggle: (v) {
                                _cubit.setStatusFilter(
                                    v ? 'INACTIVE' : 'ACTIVE');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Loading ─────────────────────────────────────────────
              if (state.isLoading)
                const LedgerListShimmer()

              // ── Error ────────────────────────────────────────────────
              else if (state.hasError && state.allLedgers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline,
                          size: 56,
                          color: AppColors.errorColor
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load ledgers.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(
                            fontSize: 15,
                            color: AppColors.billingTextColor),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: _cubit.loadInitial,
                          child: const Text('Retry')),
                    ],
                  ),
                )

              // ── Empty ────────────────────────────────────────────────
              else if (state.visibleLedgers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 56,
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No ledger accounts match the current filters.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(
                            fontSize: 15,
                            color: AppColors.billingTextColor),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Reset filters')),
                    ],
                  ),
                )

              // ── List ─────────────────────────────────────────────────
              else ...[
                if (widget.onLoadMoreNeeded != null)
                  Builder(builder: (_) {
                    WidgetsBinding.instance.addPostFrameCallback((__) {
                      if (mounted) widget.onLoadMoreNeeded!();
                    });
                    return const SizedBox.shrink();
                  }),
                ...state.visibleLedgers.map(
                  (ledger) {
                    final isActive = ledger.status != 'INACTIVE';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: LedgerCard(
                        ledgerName: ledger.name,
                        type: ledger.category ?? ledger.type,
                        openBalance: ledger.openBalance,
                        isActive: isActive,
                        onView: () => _onView(ledger),
                        onEdit: isActive ? () => _onEdit(ledger) : null,
                        onDeactivate:
                            isActive ? () => _onDeactivate(ledger) : null,
                        onReactivate:
                            !isActive ? () => _onReactivate(ledger) : null,
                        onDelete:
                            !isActive ? () => _onDelete(ledger) : null,
                      ),
                    );
                  },
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
