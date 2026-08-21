import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../../../../app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_transaction_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/ledger_detail_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/add_transaction_dialog.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/models/ledger_account_model.dart';
import 'package:wowcare/presentation/features/billing/widgets/staff_style_card.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/gradient_background.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

const _kPrimary = Color(0xff573353);

class LedgerDetailScreen extends StatefulWidget {
  const LedgerDetailScreen({required this.ledger, super.key});

  final LedgerAccountModel ledger;

  @override
  State<LedgerDetailScreen> createState() => _LedgerDetailScreenState();
}

class _LedgerDetailScreenState extends State<LedgerDetailScreen> {
  late final LedgerDetailCubit _cubit = GetIt.instance<LedgerDetailCubit>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _cubit.init(widget.ledger.id);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  void _onScroll() => _maybeLoadNextPage();

  void _maybeLoadNextPage() {
    if (!_scrollController.hasClients) return;
    final s = _cubit.state;
    if (s.isLoadingMore || !s.hasMore) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) {
      unawaited(_cubit.loadNextPage());
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 400) {
      unawaited(_cubit.loadNextPage());
    }
  }

  Future<void> _addTransaction() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          ledgerCode: widget.ledger.id,
          onSave: (params) => _cubit.addTransaction(params),
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Transaction added.',
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);
    final EdgeInsets contentPadding = ResponsiveSizing.contentPadding(context);
    final bool isTablet = MediaQuery.of(context).size.width >= 600;

    return BlocProvider<LedgerDetailCubit>.value(
      value: _cubit,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: CustomAppBar(hasBackButton: true),
          body: GradientBackground(
            child: SafeArea(
              top: false,
              bottom: true,
              child: BlocBuilder<LedgerDetailCubit, LedgerDetailState>(
                builder: (context, state) {
                  final ledger = state.ledger ?? widget.ledger;
                  return CustomRefreshIndicator(
                    onRefresh: () async {
                      _cubit.init(widget.ledger.id);
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: contentPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header: title + add button ────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ledger.name,
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary,
                                          height: titleLineHeight,
                                        ),
                                      ),
                                      _LedgerSubtitle(
                                        ledger: ledger,
                                        isLoading: state.isLoadingLedger,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GradientAddButton(
                                  onTap: _addTransaction,
                                  isTablet: isTablet,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── Date range filter ─────────────────────────
                            CustomSectionCard(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: CustomDateTimeField(
                                hasLabel: false,
                                isRangePicker: true,
                                fetchInitialTime: false,
                                label: 'Date Range',
                                onRangeSelected: (start, end) {
                                  final fromStr = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(start);
                                  final toStr = end != null
                                      ? DateFormat('yyyy-MM-dd').format(end)
                                      : fromStr;
                                  unawaited(
                                    _cubit.setDateRange(
                                      from: fromStr,
                                      to: toStr,
                                    ),
                                  );
                                },
                              ),
                            ),

                            // ── Body ──────────────────────────────────────
                            _buildBody(state),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(LedgerDetailState state) {
    if (state.isLoading) {
      return const LedgerListShimmer();
    }

    if (state.hasError && state.transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: AppColors.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ?? 'Error loading transactions.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.billingTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _cubit.loadPage(0),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 52,
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              const Text(
                'No transactions found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.billingTextSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeLoadNextPage();
    });
    return Column(
      children: [
        ...state.transactions.map(
          (tx) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LedgerEntryCard(tx: tx),
          ),
        ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: PrimaryCircularLoader()),
          ),
      ],
    );
  }
}

// ── Ledger subtitle (slim one-liner under the name) ──────────────────────────

class _LedgerSubtitle extends StatelessWidget {
  const _LedgerSubtitle({required this.ledger, required this.isLoading});

  final LedgerAccountModel ledger;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final category = ledger.category?.isNotEmpty == true
        ? ledger.category!
        : null;
    final nature = ledger.nature?.isNotEmpty == true ? ledger.nature! : null;
    final label =
        category ?? nature ?? (ledger.type.isNotEmpty ? ledger.type : null);

    final currentBal = ledger.currentBalance ?? ledger.openBalance;
    final balType = ledger.balanceType?.isNotEmpty == true
        ? ledger.balanceType!
        : null;
    final balText =
        '\$${currentBal.toStringAsFixed(2)}'
        '${balType != null ? ' $balType' : ''}';

    const style = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.billingTextSecondary,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 12),
      child: Row(
        children: [
          if (label != null) ...[
            Text(label, style: style),
            const Text(' · ', style: style),
          ],
          Text(balText, style: style),
        ],
      ),
    );
  }
}

// ── Entry card ────────────────────────────────────────────────────────────────

class _LedgerEntryCard extends StatelessWidget {
  const _LedgerEntryCard({required this.tx});
  final LedgerTransactionEntity tx;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final bool hasDebit = tx.debit != null && tx.debit! != 0;
    final bool hasCredit = tx.credit != null && tx.credit! != 0;
    final double amount = hasDebit
        ? tx.debit!
        : hasCredit
        ? tx.credit!
        : 0.0;
    final Color amountColor = hasDebit
        ? const Color(0xFFF85A5A)
        : hasCredit
        ? const Color(0xFF4CAF50)
        : kBillingCardTextColor;
    final String amountPrefix = hasDebit
        ? '-'
        : hasCredit
        ? '+'
        : '';

    return StaffStyleCard(
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_formatDate(tx.date), style: BillingCardText.name(isTablet)),
          if (tx.type != null && tx.type!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tx.type!,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
          ],
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$amountPrefix\$${amount.toStringAsFixed(2)}',
                style: BillingCardText.value.copyWith(color: amountColor),
              ),
              if (tx.balanceType != null)
                Text(
                  tx.balanceType!,
                  style: BillingCardText.note.copyWith(
                    color: AppColors.billingTextSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
      expandedChildren: [
        if (tx.contraAccount != null && tx.contraAccount!.isNotEmpty) ...[
          StaffCardDetailRow(label: 'Contra Ledger', value: tx.contraAccount!),
          const SizedBox(height: 10),
        ],
        if (tx.description != null && tx.description!.isNotEmpty) ...[
          StaffCardDetailRow(label: 'Narration', value: tx.description!),
          const SizedBox(height: 10),
        ],
        if (hasDebit) ...[
          StaffCardDetailRow(
            label: 'Debit',
            value: '\$${tx.debit!.toStringAsFixed(2)}',
            valueColor: const Color(0xFFF85A5A),
          ),
          const SizedBox(height: 10),
        ],
        if (hasCredit) ...[
          StaffCardDetailRow(
            label: 'Credit',
            value: '\$${tx.credit!.toStringAsFixed(2)}',
            valueColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 10),
        ],
        StaffCardDetailRow(
          label: 'Running Balance',
          value:
              '\$${tx.balance.toStringAsFixed(2)}'
              '${tx.balanceType != null ? ' ${tx.balanceType}' : ''}',
        ),
      ],
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final d = DateFormat('yyyy-MM-dd').parse(raw);
      return DateFormat('MMM d, yy').format(d);
    } catch (_) {
      return raw;
    }
  }
}
