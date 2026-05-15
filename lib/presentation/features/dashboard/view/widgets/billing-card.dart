import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../../shared/common/widgets/gredient-minimze-button.dart';

class BillingCard extends StatefulWidget {
  const BillingCard({super.key});

  @override
  State<BillingCard> createState() => BillingCardState();
}

class BillingCardState extends State<BillingCard> {
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            children: [
              Row(
                children: [
                  const Text(
                    'Billing',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff2E2439),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons.north_east_rounded,
                    color: AppColors.themeColor.withOpacity(0.8),
                    size: 28,
                  ),
                ],
              ),

              const Spacer(),

              GradientToggleButton(
                minimized: _minimized,
                onTap: () {
                  setState(() {
                    _minimized = !_minimized;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (!_minimized) ...[
            /// MONTH DROPDOWN
            Row(
              children: [
                SizedBox(
                  width: 190,
                  child: CustomDropdown(
                    hintText: 'March',
                    items: const ['January', 'February', 'March', 'April'],
                    onSelect: (_) {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            /// AMOUNT INVOICED HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Amount Invoiced',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

                /// RIGHT SIDE VALUE
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '\$ 97,450',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.themeColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.moving_rounded,
                          color: AppColors.successColor,
                          size: 12,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          '5% vs  last month',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 36),

            /// BILLING GRID
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBillingStatusRow(
                  label: 'Paid',
                  amount: '\$ 80,350',
                  percentage: '80%',
                  percentageColor: Colors.green,
                ),

                _buildBillingStatusRow(
                  label: 'In-Process',
                  amount: '\$ 10,400',
                  percentage: '20%',
                  percentageColor: Color(0xFFFFC107),
                ),

                _buildBillingStatusRow(
                  label: 'Outstanding',
                  amount: '\$ 6,700',
                  percentage: '8%',
                  percentageColor: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 40),

            Divider(
              color: AppColors.primaryColor.withOpacity(0.08),
              thickness: 1,
            ),

            const SizedBox(height: 28),

            /// YEAR DROPDOWN
            Row(
              children: [
                SizedBox(
                  width: 190,
                  child: CustomDropdown(
                    hintText: '2024',
                    items: const ['2022', '2023', '2024'],
                    onSelect: (_) {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            /// REVENUE HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Revenue (YTD)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '\$1M',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: AppColors.themeColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.moving_rounded,
                          color: AppColors.successColor,
                          size: 20,
                        ),

                        const SizedBox(width: 6),

                        Text(
                          '3% vs  last year total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            /// BAR CHART
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 70,

                  borderData: FlBorderData(show: false),

                  gridData: FlGridData(show: false),

                  titlesData: FlTitlesData(
                    show: true,

                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    /// LEFT TITLES
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 42,
                        showTitles: true,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}K',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                    ),

                    /// BOTTOM TITLES
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Ja',
                            'Fe',
                            'Ma',
                            'Ap',
                            'Ma',
                            'Ju',
                            'Ju',
                            'Au',
                            'Se',
                            'Oc',
                            'No',
                            'De',
                          ];

                          return SideTitleWidget(
                            meta: meta,
                            space: 14, // SPACE BETWEEN CHART AND MONTHS
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8, // SPACE BETWEEN MONTHS
                              ),
                              child: Text(
                                months[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  /// BARS
                  barGroups: [90, 89, 91, 94, 98, 95, 94, 94, 94, 94, 94, 94]
                      .asMap()
                      .entries
                      .map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.toDouble(),
                              width: 10,
                              borderRadius: BorderRadius.circular(0),
                              gradient: AppColors.buildPrimaryGradient(),
                            ),
                          ],
                        );
                      })
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillingStatusRow({
    required String label,
    required String amount,
    required String percentage,
    required Color percentageColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            amount,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.themeColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            percentage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: percentageColor,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
