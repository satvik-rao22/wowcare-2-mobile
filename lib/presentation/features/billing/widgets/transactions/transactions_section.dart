import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/cubit/family_summary_cubit.dart';
import 'package:wowcare/presentation/features/billing/cubit/transactions_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/family_summary_list.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';

class TransactionsSection extends StatefulWidget {
  const TransactionsSection({super.key, this.onRegisterRefresh});

  /// Lets the parent (Billing page) trigger a pull-to-refresh of this tab.
  final void Function(Future<void> Function())? onRegisterRefresh;

  @override
  State<TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<TransactionsSection> {
  late final TransactionsCubit _cubit = serviceLocator<TransactionsCubit>();
  late final FamilySummaryCubit _familyCubit =
      serviceLocator<FamilySummaryCubit>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit.loadOverview();
    _familyCubit.load();
    widget.onRegisterRefresh?.call(_refresh);
  }

  /// Reloads the overview totals and the family list together.
  Future<void> _refresh() async {
    await Future.wait([_cubit.loadOverview(), _familyCubit.load()]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    _familyCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionsCubit>.value(value: _cubit),
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
          builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 4),
              AccountingDateRangeSelector(
                initialStartDate: state.dateFrom,
                initialEndDate: state.dateTo,
                onRangeChanged: (start, end) => _cubit.setDateRange(start, end),
              ),
              const SizedBox(height: 12),
              AmountInvoicedStatBar(
                totalAmount: state.totalInvoiced,
                paidPercentage: state.paidPercent,
                grossPaidPercentage: state.grossPaidPercent,
                inProcessPercentage: state.inProcessPercent,
                unpaidPercentage: state.unpaidPercent,
                refundPercentage: state.refundPercent,
              ),
              const SizedBox(height: 12),
              _buildSearchBar(context),
              const SizedBox(height: 16),
              BlocBuilder<FamilySummaryCubit, FamilySummaryState>(
                builder: (context, familyState) {
                  return FamilySummaryList(
                    families: familyState.filteredFamilies,
                    isLoading: familyState.isLoading,
                    errorMessage: familyState.errorMessage,
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

  Widget _buildSearchBar(BuildContext context) {
    return CustomSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search by family or guardian',
                  onChanged: (value) => _familyCubit.setSearchQuery(value),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: <Widget>[
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
                    onTap: _clearSearch,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _familyCubit.clearSearch();
  }
}
