import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_floating_text_button.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_transaction_card.dart';

/// Parent Billing UI (ported layout from legacy `lib copy/.../billing_screen.dart`).
///
/// Note: This file focuses on reproducing the UI structure (tabs, headers,
/// buttons, date range selector, and empty-state list). Backend/data wiring can
/// be added incrementally as the WowCare billing domain is integrated.
class ParentBillingScreen extends StatefulWidget {
  const ParentBillingScreen({super.key});

  static const String routeName = '/parent-billing';

  @override
  State<ParentBillingScreen> createState() => _ParentBillingScreenState();
}

class _ParentBillingScreenState extends State<ParentBillingScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isInitialLoadingTransactions = false;
  bool _isPaymentLoading = false;

  // Demo siblings data (UI only)
  final List<Map<String, String>> _demoSiblings = const [
    {
      'name': 'Emma Johnson',
      'room': 'Ladybugs • Room 101',
    },
    {
      'name': 'Liam Johnson',
      'room': 'Caterpillars • Room 202',
    },
    {
      'name': 'Olivia Johnson',
      'room': 'Butterflies • Room 305',
    },
  ];

  // Demo transactions data (UI only)
  final List<DemoTransaction> _demoTransactions = [
    DemoTransaction(
      id: '1',
      type: 'Invoice',
      amount: 450.00,
      date: DateTime.now().subtract(const Duration(days: 5)),
      status: 'Unpaid',
      description: 'Monthly Tuition Fee - January 2024',
      studentName: 'Emma Johnson',
      studentRoom: 'Ladybugs • Room 101',
    ),
    DemoTransaction(
      id: '2',
      type: 'Payment',
      amount: 450.00,
      date: DateTime.now().subtract(const Duration(days: 10)),
      status: 'Completed',
      paymentMode: 'Credit Card',
      description: 'Payment for Invoice #1234',
      studentName: 'Emma Johnson',
      studentRoom: 'Ladybugs • Room 101',
    ),
    DemoTransaction(
      id: '3',
      type: 'Invoice',
      amount: 320.00,
      date: DateTime.now().subtract(const Duration(days: 8)),
      status: 'In Process',
      description: 'Activity Fee - Art Supplies',
      studentName: 'Liam Johnson',
      studentRoom: 'Caterpillars • Room 202',
    ),
    DemoTransaction(
      id: '4',
      type: 'Payment',
      amount: 280.00,
      date: DateTime.now().subtract(const Duration(days: 15)),
      status: 'Completed',
      paymentMode: 'Bank Transfer',
      description: 'Payment for Invoice #1230',
      studentName: 'Olivia Johnson',
      studentRoom: 'Butterflies • Room 305',
    ),
    DemoTransaction(
      id: '5',
      type: 'Refund',
      amount: 50.00,
      date: DateTime.now().subtract(const Duration(days: 20)),
      status: 'Completed',
      paymentMode: 'Credit Card',
      description: 'Refund for Cancelled Field Trip',
      studentName: 'Emma Johnson',
      studentRoom: 'Ladybugs • Room 101',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    // UI-only for now: keep method for pull-to-refresh parity.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() {});
  }

  void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate ??
          DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
    });
  }

  Widget _builtRangeSelector() {
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
              initialDate: _startDate,
              label: 'Date Range',
              fetchInitialTime: false,
              onRangeSelected: (start, end) => _onDateRangeSelected(start, end),
            ),
          ),
        ],
      ),
    );
  }

  Widget _builtStudentGridSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        elevation: 0,
        color: AppColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Student grid - 2 columns like original
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _demoSiblings.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final item = _demoSiblings[index];
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DocumentImageWidget(
                          fileUuid: '',
                          name: item['name'] ?? '',
                          size: 30,
                          fontSize: 12,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText.value(
                                item['name'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.value.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AppText.value(
                                item['room'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.value.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Balance and payment buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Text(
                          '\$0.00',
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.themeColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current\nBalance',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.primaryColor.withValues(alpha: 0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _isPaymentLoading
                        ? Container(
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: AppColors.buildPrimaryGradient(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(AppColors.cardColor),
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: CustomFloatingTextButton(
                                  height: 45,
                                  onPressed: () async {
                                    if (_isPaymentLoading) return;
                                    setState(() => _isPaymentLoading = true);
                                    await Future<void>.delayed(
                                      const Duration(milliseconds: 250),
                                    );
                                    if (!mounted) return;
                                    setState(() => _isPaymentLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Pay Now (parent)'),
                                      ),
                                    );
                                  },
                                  label: 'Pay Now',
                                  textStyle: AppTextStyles.button(
                                    color: AppColors.themeColor,
                                  ).copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  isFilled: false,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: CustomFloatingTextButton(
                                  height: 45,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Auto Pay (parent)'),
                                      ),
                                    );
                                  },
                                  label: 'Auto Pay',
                                  textStyle: AppTextStyles.button(
                                    color: AppColors.themeColor,
                                  ).copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  isFilled: false,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DemoTransaction> _getFilteredTransactions() {
    if (_startDate != null && _endDate != null) {
      return _demoTransactions.where((txn) {
        final txnDate = DateTime(txn.date.year, txn.date.month, txn.date.day);
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        return (txnDate.isAtSameMomentAs(start) || txnDate.isAfter(start)) &&
            (txnDate.isAtSameMomentAs(end) || txnDate.isBefore(end));
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
    }
    return List.from(_demoTransactions)
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  Widget _buildBillingTab() {
    final filteredTransactions = _getFilteredTransactions();
    
    return CustomRefreshIndicator(
      onRefresh: _refresh,
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
                _builtStudentGridSkeleton(),
                const SizedBox(height: 15),
                _builtRangeSelector(),
              ],
            ),
            const SizedBox(height: 15),
            // Transaction list below
            if (_isInitialLoadingTransactions)
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
                        _startDate != null && _endDate != null
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

  Widget _buildStatementsTab() {
    // UI-only placeholder matching the two-tab structure.
    return CustomRefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          AppText.title(
            'Statements',
            style: AppTextStyles.title.copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Statements UI will appear here once connected to your billing data source.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      body: Column(
        children: [
          Container(
            color: AppColors.cardColor,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppColors.themeColor,
                  unselectedLabelColor: AppColors.primaryColor.withValues(alpha: 0.6),
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
                    animation: _tabController.animation ?? const AlwaysStoppedAnimation(0),
                    builder: (context, child) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final tabWidth = screenWidth / 2;
                      
                      // Get text width using default TabBar text style
                      final defaultTextStyle = DefaultTextStyle.of(context).style;
                      final textStyle = defaultTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      );
                      
                      final billingText = TextPainter(
                        text: TextSpan(text: 'Billing', style: textStyle),
                        textDirection: TextDirection.ltr,
                      )..layout();
                      
                      final statementsText = TextPainter(
                        text: TextSpan(text: 'Statements', style: textStyle),
                        textDirection: TextDirection.ltr,
                      )..layout();
                      
                      // Smooth animation between tabs
                      final animationValue = _tabController.animation?.value ?? 0.0;
                      
                      // Interpolate between text widths
                      final currentTextWidth = (statementsText.size.width - billingText.size.width) * animationValue + billingText.size.width;
                      
                      // Calculate center position for each tab
                      final billingCenter = tabWidth / 2;
                      final statementsCenter = tabWidth + tabWidth / 2;
                      
                      // Interpolate between centers
                      final currentCenter = (statementsCenter - billingCenter) * animationValue + billingCenter;
                      
                      final leftOffset = currentCenter - currentTextWidth / 2;
                      
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
                _buildBillingTab(),
                _buildStatementsTab(),
              ],
            ),
          ),
        ],
      ),
      showCustomNavigationBar: true,
    );
  }
}
