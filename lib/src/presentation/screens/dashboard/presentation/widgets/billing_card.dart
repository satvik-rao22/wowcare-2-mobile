// import 'dart:math';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:schoolerp/core/common/views/coming_soon_screen.dart';
// import 'package:schoolerp/core/common/widgets/custom_dropdown.dart';
// import 'package:schoolerp/core/common/widgets/simmer_loader.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/decorations.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/services/injection_container.dart';
// import 'package:schoolerp/core/util/typedefs.dart';
// import 'package:schoolerp/features/billing/domain/entities/total_transaction.dart';
// import 'package:schoolerp/features/billing/domain/entities/yearly_revenue.dart';
// import 'package:schoolerp/features/billing/presentation/cubit/billing_cubit.dart';

// class BillingCard extends StatefulWidget {
//   const BillingCard({super.key});

//   @override
//   State<BillingCard> createState() => BillingCardState();
// }

// class BillingCardState extends State<BillingCard> {
//   static const monthsList = [
//     'January',
//     'February',
//     'March',
//     'April',
//     'May',
//     'June',
//     'July',
//     'August',
//     'September',
//     'October',
//     'November',
//     'December'
//   ];

//   int _selectedYear = DateTime.now().year;
//   String _selectedMonth = monthsList[DateTime.now().month - 1];
//   final bloc = sl<BillingCubit>();
//   @override
//   void initState() {
//     super.initState();
//     getTotalTransactions(_selectedMonth, _selectedYear);
//     bloc.getYearlyRevenue(year: _selectedYear);
//   }

//   void refreshData() {
//     getTotalTransactions(_selectedMonth, _selectedYear);
//   }

//   Future<void> getTotalTransactions(String monthName, int year) async {
//     final monthIndex = monthsList.indexWhere(
//       (m) => m.toLowerCase() == monthName.toLowerCase(),
//     );
//     final firstDay = DateTime(year, monthIndex + 1, 1).toIso8601String();
//     final lastDay = DateTime(year, monthIndex + 2, 0).toIso8601String();
//     final DataMap parameters = {
//       'date.greaterThanOrEqual': /* '2025-06-01T00:00:00.000Z', */
//           '${firstDay}Z',
//       'date.lessThanOrEqual': /* '2025-06-30T00:00:00.000Z',  */ '${lastDay}Z',
//       'sort': 'id,desc',
//       'page': '0',
//       'size': '100',
//     };

//     final data = await context
//         .read<BillingCubit>()
//         .getTotalTransactions(parameters: parameters);

//     print(data);
//   }

//   void getYearlyRevenueBloc() {
//     bloc.getYearlyRevenue(year: _selectedYear);
//   }

//   double getTotalRevenue(TotalTransactions transaction) {
//     double revenue = transaction.amountInProcess +
//         transaction.amountPaid +
//         transaction.amountUnpaid;
//     return revenue;
//   }

//   String getPercentage(double count, double total) {
//     if (total == 0.0) {
//       return '0 %';
//     }
//     return '${(count * 100 / total).toStringAsFixed(0)}%';
//   }

//   double getYearlyRevenue(YearlyRevenue revenue) {
//     return revenue.totalRevenue;
//   }

//   Widget totalTransactionShimmerItem() {
//     return Expanded(
//       child: ShimmerLoaderCard(
//         margin: const EdgeInsets.only(bottom: 16),
//         child: Container(
//           height: 75,
//           decoration: ContainerDecorations.decoration0,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(color: AppColors.cardBorderColor),
//         borderRadius: BorderRadius.circular(12),
//         color: Colors.white,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   const Text(
//                     'Billing',
//                     style: TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: CustomDropdown(
//                   hintText: monthsList[DateTime.now().month - 1],
//                   items: monthsList,
//                   onSelect: (value) {
//                     if (value != null) {
//                       getTotalTransactions(value, _selectedYear);
//                     }
//                   },
//                 ),
//               ),
//               const Expanded(flex: 2, child: SizedBox()),
//             ],
//           ),
//           const SizedBox(height: 10),
//           BlocConsumer<BillingCubit, BillingState>(
//             listener: (context, state) {},
//             builder: (context, state) {
//               if (state is BillingLoaded) {
//                 final transaction = state.totalTransactions;
//                 return Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                             child: Text(
//                           'Amount Invoice',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w500,
//                             color:
//                                 AppColors.primaryColor.withValues(alpha: 0.8),
//                           ),
//                         )),
//                         Expanded(
//                             child: Text(
//                           '\$ ${getTotalRevenue(transaction)}',
//                           style: const TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: AppColors.themeColor,
//                           ),
//                           textAlign: TextAlign.center,
//                         )),
//                       ],
//                     ),
//                     const SizedBox(height: 18),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         _buildBillingStatus(
//                           amount: '\$${transaction.amountPaid}',
//                           percentage:
//                               '${getPercentage(transaction.amountPaid, getTotalRevenue(transaction))}',
//                           label: 'Paid',
//                           percentageColor: Colors.green,
//                         ),
//                         _buildBillingStatus(
//                           amount: '\$${transaction.amountInProcess}',
//                           percentage:
//                               '${getPercentage(transaction.amountInProcess, getTotalRevenue(transaction))}',
//                           label: 'In-Process',
//                           percentageColor: Colors.yellow,
//                         ),
//                         _buildBillingStatus(
//                           amount: '\$${transaction.amountUnpaid}',
//                           percentage:
//                               '${getPercentage(transaction.amountUnpaid, getTotalRevenue(transaction))}',
//                           label: 'Outstanding',
//                           percentageColor: Colors.red,
//                         ),
//                       ],
//                     ),
//                   ],
//                 );
//               }
//               return Column(
//                 children: [
//                   Row(
//                     children: [
//                       totalTransactionShimmerItem(),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       totalTransactionShimmerItem(),
//                       const SizedBox(
//                         width: 10,
//                       ),
//                       totalTransactionShimmerItem(),
//                       const SizedBox(
//                         width: 10,
//                       ),
//                       totalTransactionShimmerItem(),
//                       const SizedBox(
//                         width: 10,
//                       ),
//                     ],
//                   ),
//                 ],
//               );
//             },
//           ),
//           const SizedBox(height: 10),
//           Divider(
//             color: AppColors.primaryColor.withValues(alpha: 0.1),
//             thickness: 1.25,
//           ),
//           const SizedBox(height: 10),
//           Row(
//             children: [
//               Expanded(
//                 child: CustomDropdown(
//                   hintText: '${_selectedYear}',
//                   items: List.generate(
//                     30,
//                     (index) {
//                       return (_selectedYear + index - 15).toString();
//                     },
//                   ),
//                   onSelect: (value) {
//                     if (value != null) {
//                       _selectedYear = int.parse(value);
//                       getYearlyRevenueBloc();
//                       getTotalTransactions(_selectedMonth, _selectedYear);
//                     }
//                   },
//                 ),
//               ),
//               const Expanded(flex: 2, child: SizedBox()),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Container(
//             child: BlocProvider(
//               create: (context) {
//                 // final bloc = sl<BillingCubit>();
//                 bloc.getYearlyRevenue(year: _selectedYear);
//                 return bloc;
//               },
//               child: BlocConsumer<BillingCubit, BillingState>(
//                 listener: (context, state) {
//                   if (state is YearlyRevenueError) {}
//                 },
//                 builder: (context, state) {
//                   if (state is YearlyRevenueLoaded) {
//                     final revenue = state.yearlyRevenue;
//                     final monthlyValues = revenue.monthlyRevenue.values
//                         .toList()
//                         .map((item) => item.toDouble())
//                         .toList();

//                     if (monthlyValues.isEmpty) {
//                       return Container(); // Return empty container if no data
//                     }

//                     final maxY =
//                         (monthlyValues.reduce((a, b) => a > b ? a : b) * 1.25)
//                             .ceilToDouble();
//                     final minY = 0.0;
//                     return Column(
//                       children: [
//                         Row(
//                           children: [
//                             Expanded(
//                                 child: Text(
//                               'Revenue (YTD)',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey.shade600,
//                               ),
//                             )),
//                             Expanded(
//                                 child: Text(
//                               '\$ ${getYearlyRevenue(revenue)}',
//                               style: const TextStyle(
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.bold,
//                                 color: AppColors.themeColor,
//                               ),
//                               textAlign: TextAlign.center,
//                             )),
//                           ],
//                         ),
//                         const SizedBox(height: 10),
//                         SizedBox(
//                           height: 200,
//                           child: BarChart(
//                             BarChartData(
//                               alignment: BarChartAlignment.spaceAround,
//                               maxY: maxY,
//                               minY: minY,
//                               barTouchData: BarTouchData(
//                                 enabled: true,
//                                 touchTooltipData: BarTouchTooltipData(
//                                   getTooltipItem:
//                                       (group, groupIndex, rod, rodIndex) {
//                                     return BarTooltipItem(
//                                       '${rod.toY.toStringAsFixed(0)}', // e.g., "12000"
//                                       const TextStyle(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                               titlesData: FlTitlesData(
//                                 show: true,
//                                 bottomTitles: AxisTitles(
//                                   sideTitles: SideTitles(
//                                     showTitles: true,
//                                     getTitlesWidget: (value, meta) {
//                                       const months = [
//                                         'Jan',
//                                         'Feb',
//                                         'Mar',
//                                         'Apr',
//                                         'May',
//                                         'Jun',
//                                         'Jul',
//                                         'Aug',
//                                         'Sep',
//                                         'Oct',
//                                         'Nov',
//                                         'Dec'
//                                       ];
//                                       return Text(
//                                         months[value.round()],
//                                         style: const TextStyle(
//                                           color: Colors.grey,
//                                           fontSize: 12,
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                                 leftTitles: AxisTitles(
//                                   sideTitles: SideTitles(
//                                     reservedSize: 30,
//                                     showTitles: true,
//                                     getTitlesWidget: (value, meta) {
//                                       return Text(
//                                         '${(value / 1000).round()}k',
//                                         style: const TextStyle(
//                                           color: Colors.grey,
//                                           fontSize: 12,
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                                 rightTitles: const AxisTitles(
//                                     sideTitles: SideTitles(showTitles: false)),
//                                 topTitles: const AxisTitles(
//                                     sideTitles: SideTitles(showTitles: false)),
//                               ),
//                               borderData: FlBorderData(show: false),
//                               gridData: FlGridData(
//                                 show: true,
//                                 drawVerticalLine: false,
//                                 drawHorizontalLine: true,
//                                 getDrawingHorizontalLine: (value) {
//                                   // Only draw the line at the bottom (top of X-axis labels)
//                                   if (value == minY) {
//                                     return FlLine(
//                                       color: Colors.grey.withOpacity(0.5),
//                                       strokeWidth: 1,
//                                     );
//                                   }
//                                   return FlLine(
//                                     color: Colors.grey.withOpacity(0.2),
//                                     strokeWidth: 1,
//                                   );
//                                 },
//                               ),
//                               barGroups: List.generate(12, (index) {
//                                 final value = index < monthlyValues.length
//                                     ? monthlyValues[index]
//                                     : 0.0;
//                                 return BarChartGroupData(
//                                   x: index,
//                                   barRods: [
//                                     BarChartRodData(
//                                       toY: value,
//                                       gradient:
//                                           AppColors.buildPrimaryGradient(),
//                                       width: 10,
//                                       borderRadius: BorderRadius.circular(0),
//                                     ),
//                                   ],
//                                 );
//                               }),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   }
//                   return ShimmerLoaderCard(
//                     margin: const EdgeInsets.only(bottom: 16),
//                     child: Container(
//                       height: 300,
//                       decoration: ContainerDecorations.decoration0,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildBillingStatus({
//     required String amount,
//     required String percentage,
//     required String label,
//     required Color percentageColor,
//   }) {
//     return Column(
//       children: [
//         Text(
//           amount,
//           style: const TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: AppColors.themeColor,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           percentage,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: percentageColor,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: AppColors.primaryColor.withValues(alpha: 0.8),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInvoiceStatus(String label, String count) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 18,
//             color: Colors.grey,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           count,
//           style: const TextStyle(
//             fontSize: 32,
//             fontWeight: FontWeight.bold,
//             color: AppColors.themeColor,
//           ),
//         ),
//       ],
//     );
//   }
// }
