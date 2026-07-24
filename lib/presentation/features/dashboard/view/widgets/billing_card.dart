import 'package:fl_chart/fl_chart.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_analytics_entity.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/analytics_cubit.dart';
import 'package:wowcare/presentation/features/billing/cubit/transactions_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/billing_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';

// ---------------------------------------------------------------------------
// BillingCard widget (admin dashboard)
//
// Monthly totals (Amount Invoiced / Net Paid / In-Process / Outstanding) come
// from the invoice overview API via [TransactionsCubit.loadOverview] scoped to
// the selected month's date range. The yearly revenue chart comes from the
// invoice analytics API via [AnalyticsCubit].
// ---------------------------------------------------------------------------

class BillingCard extends StatelessWidget {
  const BillingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = AppTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionsCubit>(
          create: (_) => serviceLocator<TransactionsCubit>()
            ..loadOverview(dateFrom: monthStart, dateTo: monthEnd),
        ),
        BlocProvider<AnalyticsCubit>(
          create: (_) => serviceLocator<AnalyticsCubit>()..load(),
        ),
      ],
      child: const _BillingCardBody(),
    );
  }
}

class _BillingCardBody extends StatefulWidget {
  const _BillingCardBody();

  @override
  State<_BillingCardBody> createState() => _BillingCardBodyState();
}

class _BillingCardBodyState extends State<_BillingCardBody> {
  static const _monthsList = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _monthAbbr = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

  bool _minimized = false;
  int _selectedYear = AppTime.now().year;
  String _selectedMonth = _monthsList[AppTime.now().month - 1];

  /// 1-based month number of the current monthly-section selection.
  int get _monthIndex => _monthsList.indexOf(_selectedMonth) + 1;

  Future<void> _reloadMonthlyOverview() {
    // The monthly section is scoped to the selected month within the current
    // calendar year (the year picker below only drives the revenue chart).
    final year = AppTime.now().year;
    final from = DateTime(year, _monthIndex, 1);
    final to = DateTime(year, _monthIndex + 1, 0, 23, 59, 59);
    return context
        .read<TransactionsCubit>()
        .loadOverview(dateFrom: from, dateTo: to);
  }

  // ---------------------------------------------------------------------------
  // Helper calculations
  // ---------------------------------------------------------------------------

  /// Denominator shared by the three percentage columns.
  double _getTotalAllAmounts(InvoiceOverviewEntity o) =>
      o.netPaid + o.inProcess + o.outstanding;

  String _getPercentage(double count, double total) {
    if (total == 0.0) return '0 %';
    return '${(count * 100 / total).toStringAsFixed(0)}%';
  }

  /// Maps the analytics month-value list (keyed by month name) to a dense
  /// 12-slot Jan→Dec list, defaulting missing months to 0.
  List<double> _toMonthlyValues(List<AnalyticsMonthValueEntity> data) {
    final byMonth = <String, double>{};
    for (final e in data) {
      final key = e.name.trim().toLowerCase();
      if (key.length >= 3) byMonth[key.substring(0, 3)] = e.value;
    }
    return List<double>.generate(
      12,
      (i) => byMonth[_monthAbbr[i]] ?? 0.0,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────────
          DashboardCardHeader(
            title: 'Billing',
            showRedirect: true,
            onRedirect: () => context.go(BillingScreen.routeName),
            minimized: _minimized,
            onToggle: () {
              setState(() {
                _minimized = !_minimized;
              });
            },
          ),

          const SizedBox(height: 16),

          // ── Month picker ────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      Expanded(
                        child: CustomDropdown(
                          hintText: 'Month',
                          items: _monthsList,
                          selectedItem: _selectedMonth,
                          isField: false,
                          prependHintAsSelectableItem: false,
                          onSelect: (value) {
                            if (value != null) {
                              setState(() => _selectedMonth = value);
                              _reloadMonthlyOverview();
                            }
                          },
                        ),
                      ),
                      const Expanded(flex: 2, child: SizedBox()),
                    ],
                  ),
          ),

          const SizedBox(height: 10),

          // ── Monthly totals section ──────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized
                ? const SizedBox.shrink()
                : BlocBuilder<TransactionsCubit, TransactionsState>(
                    builder: (context, state) {
                      final overview = state.overview;
                      if (overview == null) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: ShimmerLoader(height: 96),
                        );
                      }
                      return _buildMonthlySection(overview);
                    },
                  ),
          ),

          const SizedBox(height: 10),

          // ── Divider ─────────────────────────────────────────────────────────
          Divider(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            thickness: 1.25,
          ),

          const SizedBox(height: 10),

          // ── Year picker ─────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      Expanded(
                        child: CustomDropdown(
                          hintText: 'Year',
                          items: List.generate(
                            30,
                            (index) => (_selectedYear + index - 15).toString(),
                          ),
                          selectedItem: '$_selectedYear',
                          isField: false,
                          prependHintAsSelectableItem: false,
                          onSelect: (value) {
                            if (value != null) {
                              setState(() => _selectedYear = int.parse(value));
                              context
                                  .read<AnalyticsCubit>()
                                  .setYear(_selectedYear);
                            }
                          },
                        ),
                      ),
                      const Expanded(flex: 2, child: SizedBox()),
                    ],
                  ),
          ),

          const SizedBox(height: 10),

          // ── Yearly revenue chart ────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized
                ? const SizedBox.shrink()
                : BlocBuilder<AnalyticsCubit, AnalyticsState>(
                    builder: (context, state) {
                      if (state.isLoading && state.analytics == null) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: ShimmerLoader(height: 220),
                        );
                      }
                      final revenue =
                          _toMonthlyValues(state.analytics?.revenue ?? const []);
                      return _buildYearlySection(revenue);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Monthly totals section
  // ---------------------------------------------------------------------------

  Widget _buildMonthlySection(InvoiceOverviewEntity overview) {
    final totalAllAmounts = _getTotalAllAmounts(overview);
    return Column(
      children: [
        // Amount Invoice row
        Row(
          children: [
            Expanded(
              child: Text(
                'Amount Invoice',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor.withValues(alpha: 0.8),
                ),
              ),
            ),
            Expanded(
              child: Text(
                '\$ ${overview.amountInvoiced.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.themeColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Billing status columns
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildBillingStatus(
                amount: '\$${overview.netPaid.toStringAsFixed(2)}',
                percentage: _getPercentage(overview.netPaid, totalAllAmounts),
                label: 'Net Paid',
                percentageColor: Colors.green,
              ),
            ),
            Expanded(
              child: _buildBillingStatus(
                amount: '\$${overview.inProcess.toStringAsFixed(2)}',
                percentage: _getPercentage(overview.inProcess, totalAllAmounts),
                label: 'In-Process',
                percentageColor: Colors.yellow,
              ),
            ),
            Expanded(
              child: _buildBillingStatus(
                amount: '\$${overview.outstanding.toStringAsFixed(2)}',
                percentage:
                    _getPercentage(overview.outstanding, totalAllAmounts),
                label: 'Outstanding',
                percentageColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Yearly revenue chart section
  // ---------------------------------------------------------------------------

  Widget _buildYearlySection(List<double> monthlyValues) {
    final totalRevenue = monthlyValues.fold<double>(0, (a, b) => a + b);

    if (monthlyValues.every((v) => v == 0)) {
      return Column(
        children: [
          _buildRevenueHeader(totalRevenue),
          const SizedBox(height: 24),
          Text(
            'No revenue data for this year',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    final maxY = (monthlyValues.reduce((a, b) => a > b ? a : b) * 1.25)
        .ceilToDouble();
    const minY = 0.0;

    return Column(
      children: [
        _buildRevenueHeader(totalRevenue),
        const SizedBox(height: 10),
        // Bar chart
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY == 0 ? 1 : maxY,
              minY: minY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      rod.toY.toStringAsFixed(0),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const months = [
                        'Jan',
                        'Feb',
                        'Mar',
                        'Apr',
                        'May',
                        'Jun',
                        'Jul',
                        'Aug',
                        'Sep',
                        'Oct',
                        'Nov',
                        'Dec',
                      ];
                      final i = value.round();
                      if (i < 0 || i >= months.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        months[i],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    reservedSize: 30,
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${(value / 1000).round()}k',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) {
                  // Solid line at the base of the bars; faint elsewhere
                  if (value == minY) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.5),
                      strokeWidth: 1,
                    );
                  }
                  return FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              barGroups: List.generate(12, (index) {
                final value = index < monthlyValues.length
                    ? monthlyValues[index]
                    : 0.0;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      gradient: AppColors.buildPrimaryGradient(),
                      width: 10,
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueHeader(double totalRevenue) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Revenue (YTD)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '\$ ${totalRevenue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.themeColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Per-status billing column (Net Paid / In-Process / Outstanding)
  // ---------------------------------------------------------------------------

  Widget _buildBillingStatus({
    required String amount,
    required String percentage,
    required String label,
    required Color percentageColor,
  }) {
    return Column(
      children: [
        Text(
          amount,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.themeColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: percentageColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// Month / year pickers use the shared `CustomDropdown`
// (lib/shared/common/widgets/custom_dropdown.dart).
