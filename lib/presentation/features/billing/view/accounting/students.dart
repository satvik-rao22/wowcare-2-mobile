import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/billing/model/billing_route_args.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/billing_money.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/family_summary_cubit.dart';
import 'package:wowcare/presentation/features/billing/view_model/transactions_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/family_summary_list.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/transaction_details_screen.dart';
import 'package:wowcare/shared/common/view/filter_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class StudentsAccountingSection extends StatefulWidget {
  const StudentsAccountingSection({
    super.key,
    this.onRegisterRefresh,
    this.initialShowOutstanding = false,
    this.onNavigateToTransactions,
  });

  /// Lets the parent (Billing page) trigger a pull-to-refresh of this tab.
  final void Function(Future<void> Function())? onRegisterRefresh;

  /// When true, enables the "outstanding only" family filter on first build —
  /// set when the user taps Outstanding from the Transactions tab.
  final bool initialShowOutstanding;

  /// Routes a list-filter tap (Net Paid / Paid / In Process / Refund) to the
  /// Transactions tab with that filter pre-applied.
  final ValueChanged<BillingSummaryFilter>? onNavigateToTransactions;

  @override
  State<StudentsAccountingSection> createState() =>
      _StudentsAccountingSectionState();
}

class _StudentsAccountingSectionState extends State<StudentsAccountingSection> {
  late final TransactionsCubit _overviewCubit =
      serviceLocator<TransactionsCubit>();
  late final FamilySummaryCubit _familyCubit =
      serviceLocator<FamilySummaryCubit>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _overviewCubit.loadOverview();
    _familyCubit.load();
    if (widget.initialShowOutstanding) {
      _familyCubit.setShowOutstandingOnly(true);
    }
    widget.onRegisterRefresh?.call(_refresh);
  }

  /// Handles a summary-card tap. Outstanding toggles the family filter in place
  /// (we're already on this tab); the four list filters route to Transactions.
  void _onFilterTap(BillingSummaryFilter filter) {
    if (filter == BillingSummaryFilter.outstanding) {
      _familyCubit
          .setShowOutstandingOnly(!_familyCubit.state.showOutstandingOnly);
      return;
    }
    widget.onNavigateToTransactions?.call(filter);
  }

  /// Opens the funnel sheet for the family list. Options come from the loaded
  /// rows (see [FamilySummaryState.availableInvoiceStatuses]), so this waits
  /// for data rather than showing an empty sheet.
  Future<void> _openFilter() async {
    final state = _familyCubit.state;
    final statuses = state.availableInvoiceStatuses;
    final methods = state.availablePaymentMethods;

    if (statuses.isEmpty && methods.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: BillingStrings.noFilterOptionsYet,
        isWarning: true,
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FilterScreen(
          sections: [
            if (statuses.isNotEmpty)
              FilerSection(
                label: BillingStrings.lastPaymentStatus,
                items: statuses,
                initialSelected: state.invoiceStatuses.toList(),
              ),
            if (methods.isNotEmpty)
              FilerSection(
                label: BillingStrings.paymentMethod,
                items: methods,
                initialSelected: state.paymentMethods.toList(),
              ),
          ],
          // A section left out above (no options) yields no key here, which
          // clears that dimension — correct, since it had nothing to select.
          onApply: (applied) => _familyCubit.setFilters(
            invoiceStatuses:
                (applied[BillingStrings.lastPaymentStatus] ?? const <String>[])
                    .toSet(),
            paymentMethods:
                (applied[BillingStrings.paymentMethod] ?? const <String>[])
                    .toSet(),
          ),
        ),
      ),
    );
  }

  /// Reloads the overview totals and the family list together.
  Future<void> _refresh() async {
    await Future.wait([_overviewCubit.loadOverview(), _familyCubit.load()]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _overviewCubit.close();
    _familyCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Non-scrollable content; parent page handles vertical scrolling.
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionsCubit>.value(value: _overviewCubit),
        BlocProvider<FamilySummaryCubit>.value(value: _familyCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TransactionsCubit, TransactionsState>(
            listenWhen: (p, c) =>
                p.errorMessage != c.errorMessage && c.errorMessage != null,
            listener: (context, state) => CoreUtils.showTopSnackBar(
              context: context,
              message: state.errorMessage!,
              isError: true,
            ),
          ),
          BlocListener<FamilySummaryCubit, FamilySummaryState>(
            listenWhen: (p, c) =>
                p.errorMessage != c.errorMessage && c.errorMessage != null,
            listener: (context, state) => CoreUtils.showTopSnackBar(
              context: context,
              message: state.errorMessage!,
              isError: true,
            ),
          ),
        ],
        child: BlocBuilder<TransactionsCubit, TransactionsState>(
          builder: (context, overview) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountingDateRangeSelector(
                initialStartDate: overview.dateFrom,
                initialEndDate: overview.dateTo,
                onRangeChanged: (start, end) =>
                    _overviewCubit.setDateRange(start, end),
              ),
              const SizedBox(height: 8),
              BlocBuilder<FamilySummaryCubit, FamilySummaryState>(
                buildWhen: (p, c) =>
                    p.showOutstandingOnly != c.showOutstandingOnly,
                builder: (context, familyState) => AmountInvoicedStatBar(
                  totalAmount: overview.totalInvoiced,
                  netPaidAmount: overview.netPaidAmount,
                  paidAmount: overview.paidAmount,
                  inProcessAmount: overview.inProcessAmount,
                  outstandingAmount: overview.outstandingAmount,
                  refundedAmount: overview.refundedAmount,
                  selectedFilter: familyState.showOutstandingOnly
                      ? BillingSummaryFilter.outstanding
                      : null,
                  onFilterTap: _onFilterTap,
                ),
              ),
              const SizedBox(height: 8),
              CustomSectionCard(
                margin: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomSearchBar(
                        controller: _searchController,
                        hintText: BillingStrings.search,
                        onChanged: (value) =>
                            _familyCubit.setSearchQuery(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                            color: AppColors.billingCardColor,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _openFilter,
                              child: Center(
                                // Dot marks an applied filter, which is
                                // otherwise invisible once the sheet closes.
                                child: BlocSelector<FamilySummaryCubit,
                                    FamilySummaryState, bool>(
                                  selector: (s) => s.hasActiveFilters,
                                  builder: (context, hasActiveFilters) => Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      SvgPicture.asset(
                                        MediaRes.filterIcon,
                                        width: 20,
                                        height: 20,
                                      ),
                                      if (hasActiveFilters)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: AppColors.errorColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors
                                                    .billingCardColor,
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        CustomClearAllChip(
                          onTap: () {
                            _searchController.clear();
                            _familyCubit.clearSearch();
                            _familyCubit.clearFilters();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              BlocBuilder<FamilySummaryCubit, FamilySummaryState>(
                builder: (context, familyState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Row(
                          children: [
                            CustomToggle(
                              key: ValueKey(familyState.showOutstandingOnly),
                              label: BillingStrings.showTotalOutstanding,
                              labelStyle: AppTextStyles.title.copyWith(
                                fontSize: 15,
                                color: AppColors.billingTextColor,
                              ),
                              isToggled: familyState.showOutstandingOnly,
                              onToggle: (val) =>
                                  _familyCubit.setShowOutstandingOnly(val),
                            ),
                            const Spacer(),
                            Text(
                              billingAmount(familyState.totalOutstanding),
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FamilySummaryList(
                        families: familyState.filteredFamilies,
                        isLoading: familyState.isLoading,
                        errorMessage: familyState.errorMessage,
                        onBillingProfile: (family) => context.push(
                          TransactionDetailsScreen.routeName,
                          extra: TransactionDetailsArgs(
                            ownerType: family.ownerType,
                            ownerCode: family.ownerCode,
                            familyName: family.familyName,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
        ),
      ),
    );
  }
}
