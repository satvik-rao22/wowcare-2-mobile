import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/cubit/parent_billing_cubit.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_transaction_card.dart';
import 'package:wowcare/presentation/features/billing/widgets/sibling_cards_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_statements_tab.dart';
import 'package:wowcare/presentation/features/billing/view/auto_pay_payment_methods_screen.dart';
import 'package:wowcare/presentation/features/billing/view/pay_now_amount_screen.dart';

/// Parent Billing UI (ported layout from legacy `lib copy/.../billing_screen.dart`).
///
/// State (date range, demo transactions, loading flags) lives in
/// [ParentBillingCubit]; this widget only renders it and forwards user intent.
class ParentBillingScreen extends StatefulWidget {
  const ParentBillingScreen({super.key});

  static const String routeName = '/parent-billing';

  @override
  State<ParentBillingScreen> createState() => _ParentBillingScreenState();
}

class _ParentBillingScreenState extends State<ParentBillingScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  ParentBillingCubit get _cubit => context.read<ParentBillingCubit>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cubit.loadInitial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _builtRangeSelector(ParentBillingState state) {
    return Card(
      elevation: 0,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.label(
                  'Select Date Range',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.billingGreyMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomDateTimeField(
              hasLabel: false,
              isRangePicker: true,
              initialDate: state.startDate,
              label: 'Date Range',
              fetchInitialTime: false,
              onRangeSelected: (start, end) => _cubit.setDateRange(start, end),
            ),
          ),
        ],
      ),
    );
  }

  Widget _builtStudentGridSkeleton(ParentBillingState state) {
    return SiblingCardsWidget(
      siblings: state.siblings,
      currentBalance: 0.0, // TODO: Calculate from actual data
      isPaymentLoading: state.isPaymentLoading,
      isAutoPayLoading: state.isAutoPayLoading,
      onPayNow: () async {
        if (state.isPaymentLoading) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const PayNowAmountScreen(),
          ),
        );
      },
      onAutoPay: () async {
        if (state.isAutoPayLoading) return;
        _cubit.beginAutoPay();
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AutoPayPaymentMethodsScreen(),
          ),
        );
        if (!mounted) return;
        _cubit.endAutoPay();
        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Auto Pay settings updated')),
          );
        }
      },
    );
  }

  Widget _buildBillingTab(ParentBillingState state) {
    final filteredTransactions = state.filteredTransactions;

    return CustomRefreshIndicator(
      onRefresh: _cubit.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  AppText.title('Billing'),
                ],
              ),
            ),
            // Sibling cards and date range
            Column(
              children: [
                _builtStudentGridSkeleton(state),
                const SizedBox(height: 15),
                _builtRangeSelector(state),
              ],
            ),
            const SizedBox(height: 15),
            // Transaction list below
            if (state.isInitialLoadingTransactions)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const AppText.value('No records found'),
                      const SizedBox(height: 8),
                      Text(
                        state.hasDateRange
                            ? 'No transactions available for the selected date range'
                            : 'No transactions available',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: filteredTransactions.map((txn) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ParentTransactionCard(transaction: txn),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementsTab(ParentBillingState state) {
    return ParentStatementsTab(
      familyChildren: state.siblings.map((sibling) {
        return {
          'id': sibling.hashCode,
          'name': sibling['name'],
          'fullName': sibling['name'],
          'room': sibling['room'],
          'roomName': sibling['room'],
        };
      }).toList(),
      customStartDate: state.startDate,
      customEndDate: state.endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentBillingCubit, ParentBillingState>(
      builder: (context, state) {
        return GlobalScaffold(
          body: Column(
            children: [
              Container(
                color: AppColors.cardColor,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppColors.themeColor,
                      unselectedLabelColor:
                          AppColors.primaryColor.withValues(alpha: 0.6),
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicatorColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(text: 'Billing'),
                        Tab(text: 'Statements'),
                      ],
                    ),
                    // Custom gradient indicator line positioned below tabs
                    SizedBox(
                      height: 2.5,
                      child: AnimatedBuilder(
                        animation: _tabController.animation ??
                            const AlwaysStoppedAnimation(0),
                        builder: (context, child) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final tabWidth = screenWidth / 2;

                          // Get text width using default TabBar text style
                          final defaultTextStyle =
                              DefaultTextStyle.of(context).style;
                          final textStyle = defaultTextStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          );

                          final billingText = TextPainter(
                            text: TextSpan(text: 'Billing', style: textStyle),
                            textDirection: TextDirection.ltr,
                          )..layout();

                          final statementsText = TextPainter(
                            text:
                                TextSpan(text: 'Statements', style: textStyle),
                            textDirection: TextDirection.ltr,
                          )..layout();

                          // Smooth animation between tabs
                          final animationValue =
                              _tabController.animation?.value ?? 0.0;

                          // Interpolate between text widths
                          final currentTextWidth = (statementsText.size.width -
                                      billingText.size.width) *
                                  animationValue +
                              billingText.size.width;

                          // Calculate center position for each tab
                          final billingCenter = tabWidth / 2;
                          final statementsCenter = tabWidth + tabWidth / 2;

                          // Interpolate between centers
                          final currentCenter = (statementsCenter -
                                      billingCenter) *
                                  animationValue +
                              billingCenter;

                          final leftOffset =
                              currentCenter - currentTextWidth / 2;

                          return Stack(
                            children: [
                              Positioned(
                                left: leftOffset,
                                width: currentTextWidth,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.buildPrimaryGradient(),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBillingTab(state),
                    _buildStatementsTab(state),
                  ],
                ),
              ),
            ],
          ),
          showCustomNavigationBar: true,
        );
      },
    );
  }
}
