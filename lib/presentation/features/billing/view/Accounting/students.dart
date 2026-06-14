import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/cubit/family_summary_cubit.dart';
import 'package:wowcare/presentation/features/billing/cubit/transactions_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/family_summary_list.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class StudentsAccountingSection extends StatefulWidget {
  const StudentsAccountingSection({super.key, this.onRegisterRefresh});

  /// Lets the parent (Billing page) trigger a pull-to-refresh of this tab.
  final void Function(Future<void> Function())? onRegisterRefresh;

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
    widget.onRegisterRefresh?.call(_refresh);
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
              AmountInvoicedStatBar(
                totalAmount: overview.totalInvoiced,
                paidPercentage: overview.paidPercent,
                grossPaidPercentage: overview.grossPaidPercent,
                inProcessPercentage: overview.inProcessPercent,
                unpaidPercentage: overview.unpaidPercent,
                refundPercentage: overview.refundPercent,
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
                        hintText: 'Search',
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
                              label: 'Show Total Outstanding',
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
