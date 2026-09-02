import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/billing/model/billing_route_args.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/cubit/family_summary_cubit.dart';
import 'package:wowcare/presentation/features/billing/cubit/transactions_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/family_summary_list.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/transaction_details_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/app/theme/media_res.dart';
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
                              onTap: () {},
                              child: Center(
                                child: SvgPicture.asset(
                                  MediaRes.filterIcon,
                                  width: 20,
                                  height: 20,
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
                              '\$${familyState.totalOutstanding.toStringAsFixed(0)}',
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
