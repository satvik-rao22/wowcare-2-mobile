import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';

// ---------------------------------------------------------------------------
// Local mock data models (UI-only — no entity imports)
// ---------------------------------------------------------------------------

/// Snapshot of monthly billing totals for a selected period.
class _TotalTransactions {
  const _TotalTransactions({
    required this.totalAmountInvoiced,
    required this.netAmountPaid,
    required this.amountInProcess,
    required this.amountUnpaid,
  });

  final double totalAmountInvoiced;
  final double netAmountPaid;
  final double amountInProcess;
  final double amountUnpaid;
}

/// Year-to-date revenue with per-month breakdown.
class _YearlyRevenue {
  const _YearlyRevenue({
    required this.totalRevenue,
    required this.monthlyRevenue,
  });

  final double totalRevenue;

  /// Keys are month names (Jan–Dec order); values are revenue amounts.
  final Map<String, double> monthlyRevenue;
}

// ---------------------------------------------------------------------------
// Hardcoded mock data
// ---------------------------------------------------------------------------

/// Realistic per-month transaction mock for any selected month.
const _mockTransaction = _TotalTransactions(
  totalAmountInvoiced: 48750.00,
  netAmountPaid: 31200.00,
  amountInProcess: 9850.00,
  amountUnpaid: 7700.00,
);

/// Realistic YTD revenue mock (calendar year).
const _mockYearlyRevenue = _YearlyRevenue(
  totalRevenue: 312400.00,
  monthlyRevenue: {
    'Jan': 22400,
    'Feb': 18900,
    'Mar': 24700,
    'Apr': 27300,
    'May': 31200,
    'Jun': 29800,
    'Jul': 26500,
    'Aug': 30100,
    'Sep': 28400,
    'Oct': 33600,
    'Nov': 21500,
    'Dec': 18000,
  },
);

// ---------------------------------------------------------------------------
// BillingCard widget
// ---------------------------------------------------------------------------

class BillingCard extends StatefulWidget {
  const BillingCard({super.key});

  @override
  State<BillingCard> createState() => _BillingCardState();
}

class _BillingCardState extends State<BillingCard> {
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

  bool _minimized = false;
  int _selectedYear = DateTime.now().year;
  String _selectedMonth = _monthsList[DateTime.now().month - 1];

  // ---------------------------------------------------------------------------
  // Helper calculations (mirror original logic, operate on local mock)
  // ---------------------------------------------------------------------------

  double _getTotalRevenue(_TotalTransactions transaction) =>
      transaction.totalAmountInvoiced;

  /// Denominator shared by the three percentage columns.
  double _getTotalAllAmounts(_TotalTransactions transaction) =>
      transaction.netAmountPaid +
      transaction.amountInProcess +
      transaction.amountUnpaid;

  String _getPercentage(double count, double total) {
    if (total == 0.0) return '0 %';
    return '${(count * 100 / total).toStringAsFixed(0)}%';
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
            onRedirect: () {},
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
                : _buildMonthlySection(_mockTransaction),
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
                : _buildYearlySection(_mockYearlyRevenue),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Monthly totals section
  // ---------------------------------------------------------------------------

  Widget _buildMonthlySection(_TotalTransactions transaction) {
    final totalAllAmounts = _getTotalAllAmounts(transaction);
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
                '\$ ${_getTotalRevenue(transaction).toStringAsFixed(2)}',
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
                amount: '\$${transaction.netAmountPaid.toStringAsFixed(2)}',
                percentage: _getPercentage(
                  transaction.netAmountPaid,
                  totalAllAmounts,
                ),
                label: 'Net Paid',
                percentageColor: Colors.green,
              ),
            ),
            Expanded(
              child: _buildBillingStatus(
                amount: '\$${transaction.amountInProcess.toStringAsFixed(2)}',
                percentage: _getPercentage(
                  transaction.amountInProcess,
                  totalAllAmounts,
                ),
                label: 'In-Process',
                percentageColor: Colors.yellow,
              ),
            ),
            Expanded(
              child: _buildBillingStatus(
                amount: '\$${transaction.amountUnpaid.toStringAsFixed(2)}',
                percentage: _getPercentage(
                  transaction.amountUnpaid,
                  totalAllAmounts,
                ),
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

  Widget _buildYearlySection(_YearlyRevenue revenue) {
    final monthlyValues = revenue.monthlyRevenue.values
        .map((v) => v.toDouble())
        .toList();

    if (monthlyValues.isEmpty) return const SizedBox.shrink();

    final maxY = (monthlyValues.reduce((a, b) => a > b ? a : b) * 1.25)
        .ceilToDouble();
    const minY = 0.0;

    return Column(
      children: [
        // Revenue (YTD) header row
        Row(
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
                '\$ ${revenue.totalRevenue.toStringAsFixed(2)}',
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
        const SizedBox(height: 10),
        // Bar chart
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
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
                      return Text(
                        months[value.round()],
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
