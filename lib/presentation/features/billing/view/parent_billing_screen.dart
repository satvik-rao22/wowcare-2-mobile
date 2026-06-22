import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/cubit/parent_billing_cubit.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_transaction_card.dart';
import 'package:wowcare/presentation/features/billing/widgets/sibling_cards_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_statements_tab.dart';
import 'package:wowcare/presentation/features/billing/view/auto_pay_payment_methods_screen.dart';
import 'package:wowcare/presentation/features/billing/view/pay_now_amount_screen.dart';

/// Parent Billing UI — fetches live data from
/// `GET /api/v1/invoices/family-ledger/by-guardian`.
class ParentBillingScreen extends StatefulWidget {
  const ParentBillingScreen({super.key});

  static const String routeName = '/parent-billing';

  @override
  State<ParentBillingScreen> createState() => _ParentBillingScreenState();
}

class _ParentBillingScreenState extends State<ParentBillingScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _billingScrollController = ScrollController();

  ParentBillingCubit get _cubit => context.read<ParentBillingCubit>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _billingScrollController.addListener(_onBillingScroll);
    _cubit.load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _billingScrollController.removeListener(_onBillingScroll);
    _billingScrollController.dispose();
    super.dispose();
  }

  void _onBillingScroll() {
    if (!_billingScrollController.hasClients) return;
    final pos = _billingScrollController.position;
    if (pos.maxScrollExtent <= 0) {
      _cubit.loadNextPage();
      return;
    }
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _cubit.loadNextPage();
    }
  }

  void _maybeLoadNextBillingPage() {
    if (!_billingScrollController.hasClients) return;
    final pos = _billingScrollController.position;
    if (pos.maxScrollExtent <= 0 && _cubit.state.hasMoreTransactions) {
      _cubit.loadNextPage();
    }
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
      students: state.students,
      currentBalance: state.openBalance,
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
    return CustomRefreshIndicator(
      onRefresh: _cubit.refresh,
      child: SingleChildScrollView(
        controller: _billingScrollController,
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
            Column(
              children: [
                _builtStudentGridSkeleton(state),
                const SizedBox(height: 15),
                _builtRangeSelector(state),
              ],
            ),
            const SizedBox(height: 15),
            if (state.isLoading)
              // Shimmer cards during initial load
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: List.generate(
                    5,
                    (_) => const ParentTransactionCardShimmer(
                      margin: EdgeInsets.only(bottom: 8),
                    ),
                  ),
                ),
              )
            else if (state.errorMessage != null && state.ledger == null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _cubit.load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (state.filteredTransactions.isEmpty)
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
                          color: AppColors.primaryColor.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Builder(builder: (context) {
                // After list renders, check if we should load more
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _maybeLoadNextBillingPage();
                });
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: state.visibleTransactions.map((txn) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ParentTransactionCard(transaction: txn),
                      );
                    }).toList(),
                  ),
                );
              }),
            // Load-more indicator at bottom
            if (state.hasMoreTransactions && !state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: PrimaryCircularLoader()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementsTab(ParentBillingState state) {
    return ParentStatementsTab(
      familyChildren: state.students.map((s) {
        return <String, dynamic>{
          'code': s.code,
          'name': s.fullName,
          'fullName': s.fullName,
          'room': s.role,
          'roomName': s.role,
        };
      }).toList(),
      subscriberCode: state.ledger?.ownerCode ?? '',
      ownerType: state.ledger?.ownerType ?? 'GUARDIAN',
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
              ColoredBox(
                color: AppColors.cardColor,
                child: TabBar(
                  labelColor: AppColors.themeColor,
                  unselectedLabelColor:
                      AppColors.primaryColor.withValues(alpha: 0.6),
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: _GradientTabIndicator(
                    gradient: AppColors.buildPrimaryGradient(),
                  ),
                  tabs: const [
                    Tab(text: 'Billing'),
                    Tab(text: 'Statements'),
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

// ─── Gradient tab indicator ───────────────────────────────────────────────────

class _GradientTabIndicator extends Decoration {
  const _GradientTabIndicator({
    required this.gradient,
    this.height = 2.5,
  });

  final Gradient gradient;
  final double height;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _GradientTabPainter(gradient: gradient, height: height);
}

class _GradientTabPainter extends BoxPainter {
  _GradientTabPainter({required this.gradient, required this.height});

  final Gradient gradient;
  final double height;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size ?? Size.zero;
    final rect = Rect.fromLTWH(
      offset.dx,
      offset.dy + size.height - height,
      size.width,
      height,
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }
}
