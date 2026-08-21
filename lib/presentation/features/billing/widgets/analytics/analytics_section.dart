import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_analytics_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/analytics_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/billing/utils/billing_school_time.dart';

class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({super.key, this.onRegisterRefresh});

  final void Function(Future<void> Function())? onRegisterRefresh;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AnalyticsCubit>(
      create: (_) => serviceLocator<AnalyticsCubit>()..load(),
      child: _AnalyticsSectionBody(onRegisterRefresh: onRegisterRefresh),
    );
  }
}

class _AnalyticsSectionBody extends StatefulWidget {
  const _AnalyticsSectionBody({this.onRegisterRefresh});

  final void Function(Future<void> Function())? onRegisterRefresh;

  @override
  State<_AnalyticsSectionBody> createState() => _AnalyticsSectionBodyState();
}

class _AnalyticsSectionBodyState extends State<_AnalyticsSectionBody> {
  static const List<String> _months = <String>[
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

  static const List<String> _monthNames = [
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRegisterRefresh?.call(
        () => context.read<AnalyticsCubit>().load(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (context, state) {
        final bool isTablet = ResponsiveSizing.isTablet(context);
        final double sectionGap = isTablet ? 16 : 12;
        final int currentYear = billingSchoolCurrentYear();

        if (state.isLoading) {
          return const _AnalyticsShimmer();
        }

        if (state.errorMessage != null && state.analytics == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 14 : 13,
                      color: AppColors.billingTextColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<AnalyticsCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final analytics = state.analytics;
        final List<double> revenue = _toMonthlyValues(analytics?.revenue ?? []);
        final List<double> invoiced = _toMonthlyValues(
          analytics?.invoiced ?? [],
        );
        final List<double> refunds = _toMonthlyValues(analytics?.refunds ?? []);

        final double revenueYtd = revenue.fold(0, (a, b) => a + b);
        final double invoicedYtd = invoiced.fold(0, (a, b) => a + b);
        final double refundsYtd = refunds.fold(0, (a, b) => a + b);

        final List<AnalyticsSubsidyEntity> subsidyData =
            analytics?.subsidies ?? [];
        final double subsidiesInvoicedYtd = subsidyData.fold(
          0.0,
          (a, b) => a + b.invoiced,
        );

        final List<double> subsidyBalance = _toMonthlySubsidyValues(
          subsidyData,
          (e) => e.balance,
        );
        final List<double> subsidyInvoiced = _toMonthlySubsidyValues(
          subsidyData,
          (e) => e.invoiced,
        );
        final List<double> subsidyReceived = _toMonthlySubsidyValues(
          subsidyData,
          (e) => e.received,
        );

        final double maxSubsidyAbs = _maxAbsValue([
          ...subsidyBalance,
          ...subsidyInvoiced,
          ...subsidyReceived,
        ]);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year filter — right-aligned
            _YearSelector(
              selectedYear: state.selectedYear ?? currentYear,
              onYearChanged: (y) => context.read<AnalyticsCubit>().setYear(y),
            ),
            SizedBox(height: sectionGap),
            _AnalyticsBarCard(
              title: 'Revenue (Net Paid)',
              ytdLabel: 'Total Revenue',
              ytdAmount: revenueYtd,
              data: revenue,
              months: _months,
              gradient: AppColors.buildPrimaryGradient(
                colors: const <Color>[Color(0xFF1BB686), Color(0xFF31C9A5)],
              ),
              legendLabel: 'Revenue',
            ),
            SizedBox(height: sectionGap),
            _AnalyticsBarCard(
              title: 'Amount Invoiced',
              ytdLabel: 'Total Invoiced',
              ytdAmount: invoicedYtd,
              data: invoiced,
              months: _months,
              gradient: AppColors.buildPrimaryGradient(
                colors: const <Color>[Color(0xFF5A86FF), Color(0xFF3F7DE3)],
              ),
              legendLabel: 'Invoiced',
            ),
            SizedBox(height: sectionGap),
            _AnalyticsBarCard(
              title: 'Refunds',
              ytdLabel: 'Total Refunds',
              ytdAmount: refundsYtd,
              data: refunds,
              months: _months,
              gradient: AppColors.buildPrimaryGradient(
                colors: const <Color>[Color(0xFFFF5A68), Color(0xFFEF3D4B)],
              ),
              legendLabel: 'Refunds',
            ),
            SizedBox(height: sectionGap),
            _SubsidiesOverviewCard(
              months: _months,
              balance: subsidyBalance,
              invoiced: subsidyInvoiced,
              received: subsidyReceived,
              subsidiesInvoicedYtd: subsidiesInvoicedYtd,
              maxAbsY: maxSubsidyAbs <= 0 ? 1 : maxSubsidyAbs,
            ),
          ],
        );
      },
    );
  }

  List<double> _toMonthlyValues(List<AnalyticsMonthValueEntity> entries) {
    final result = List<double>.filled(12, 0);
    for (final e in entries) {
      final idx = _monthIndex(e.name);
      if (idx >= 0) result[idx] = e.value;
    }
    return result;
  }

  List<double> _toMonthlySubsidyValues(
    List<AnalyticsSubsidyEntity> entries,
    double Function(AnalyticsSubsidyEntity) getValue,
  ) {
    final result = List<double>.filled(12, 0);
    for (final e in entries) {
      final idx = _monthIndex(e.name);
      if (idx >= 0) result[idx] += getValue(e);
    }
    return result;
  }

  int _monthIndex(String name) {
    final lower = name.toLowerCase().trim();
    for (int i = 0; i < _monthNames.length; i++) {
      if (lower.startsWith(_monthNames[i])) return i;
    }
    return -1;
  }

  double _maxAbsValue(List<double> values) {
    double max = 0;
    for (final v in values) {
      if (v.abs() > max) max = v.abs();
    }
    return max;
  }
}

// ─── Analytics Shimmer ────────────────────────────────────────────────────────

class _AnalyticsShimmer extends StatelessWidget {
  const _AnalyticsShimmer();

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    final double gap = isTablet ? 16 : 12;
    final double chartHeight = isTablet ? 220 : 170;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Year dropdown placeholder — right-aligned
        Align(
          alignment: Alignment.centerRight,
          child: Shimmer.fromColors(
            baseColor: AppColors.grey.shade300,
            highlightColor: AppColors.grey.shade100,
            child: Container(
              height: 32,
              width: 110,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(height: gap),
        // 3 bar chart card placeholders
        for (int i = 0; i < 3; i++) ...[
          _AnalyticsCardShimmer(chartHeight: chartHeight),
          SizedBox(height: gap),
        ],
        // Subsidies card placeholder (slightly taller)
        _AnalyticsCardShimmer(chartHeight: isTablet ? 240 : 190),
      ],
    );
  }
}

class _AnalyticsCardShimmer extends StatelessWidget {
  const _AnalyticsCardShimmer({required this.chartHeight});

  final double chartHeight;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    return Shimmer.fromColors(
      baseColor: AppColors.grey.shade300,
      highlightColor: AppColors.grey.shade100,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    height: isTablet ? 16 : 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: isTablet ? 24 : 20,
                      width: 90,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: chartHeight,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                height: 12,
                width: 70,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Year Selector ────────────────────────────────────────────────────────────

class _YearSelector extends StatelessWidget {
  const _YearSelector({
    required this.selectedYear,
    required this.onYearChanged,
  });

  final int selectedYear;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final int currentYear = billingSchoolCurrentYear();
    // Years from 10 years ago through 2 years in the future (inclusive)
    final List<int> yearList = List.generate(13, (i) => currentYear - 10 + i);
    final List<String> yearStrings = yearList.map((y) => y.toString()).toList();
    final String selectedYearStr = selectedYear.toString();

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 140,
        child: CustomDropdown(
          label: null,
          hintText: 'Select Year',
          items: yearStrings,
          selectedItem: selectedYearStr,
          isRequired: false,
          showAsterisk: false,
          onSelect: (selected) {
            if (selected != null && selected.isNotEmpty) {
              final year = int.tryParse(selected);
              onYearChanged(year);
            }
          },
        ),
      ),
    );
  }
}

// ─── Bar card ─────────────────────────────────────────────────────────────────

class _AnalyticsBarCard extends StatelessWidget {
  const _AnalyticsBarCard({
    required this.title,
    required this.ytdLabel,
    required this.ytdAmount,
    required this.data,
    required this.months,
    required this.gradient,
    required this.legendLabel,
  });

  final String title;
  final String ytdLabel;
  final double ytdAmount;
  final List<double> data;
  final List<String> months;
  final Gradient gradient;
  final String legendLabel;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    final double maxY = _maxValue(data);
    final NumberFormatHelper formatter = NumberFormatHelper();

    return CustomSectionCard(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.billingTextColor,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ytdLabel,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.billingTextColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatter.currency(ytdAmount),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.billingTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SimpleBarChart(
            data: data,
            months: months,
            maxY: maxY,
            gradient: gradient,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                legendLabel,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: isTablet ? 13 : 12,
                  color: AppColors.billingTextColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Subsidies card ───────────────────────────────────────────────────────────

class _SubsidiesOverviewCard extends StatelessWidget {
  const _SubsidiesOverviewCard({
    required this.months,
    required this.balance,
    required this.invoiced,
    required this.received,
    required this.subsidiesInvoicedYtd,
    required this.maxAbsY,
  });

  final List<String> months;
  final List<double> balance;
  final List<double> invoiced;
  final List<double> received;
  final double subsidiesInvoicedYtd;
  final double maxAbsY;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    final NumberFormatHelper formatter = NumberFormatHelper();

    return CustomSectionCard(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Subsidies Overview',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.billingTextColor,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Subsidies Invoiced',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.billingTextColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatter.currency(subsidiesInvoicedYtd),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.billingTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GroupedBarChart(
            months: months,
            maxAbsY: maxAbsY,
            series: <_ChartSeries>[
              _ChartSeries(
                label: 'Balance',
                data: balance,
                gradientColors: const <Color>[
                  Color(0xFFFFC453),
                  Color(0xFFFFA600),
                ],
              ),
              _ChartSeries(
                label: 'Invoiced',
                data: invoiced,
                gradientColors: const <Color>[
                  Color(0xFF8E6EFF),
                  Color(0xFF6A57E0),
                ],
              ),
              _ChartSeries(
                label: 'Received',
                data: received,
                gradientColors: const <Color>[
                  Color(0xFF2BC7A2),
                  Color(0xFF1CA482),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chart widgets ────────────────────────────────────────────────────────────

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({
    required this.data,
    required this.months,
    required this.maxY,
    required this.gradient,
  });

  final List<double> data;
  final List<String> months;
  final double maxY;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    final double chartHeight = isTablet ? 220 : 170;
    final double rowLabelWidth = isTablet ? 56 : 46;
    final double minPlotWidth = isTablet ? 720 : 560;

    return SizedBox(
      height: chartHeight + 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: rowLabelWidth,
            height: chartHeight,
            child: _YAxisLabels(maxY: maxY, steps: 4, formatCompact: true),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minPlotWidth,
                child: _PlotArea(
                  months: months,
                  maxY: maxY,
                  chartHeight: chartHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List<Widget>.generate(data.length, (int index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 6 : 4,
                          ),
                          child: _SingleBar(
                            month: months[index],
                            value: data[index],
                            maxY: maxY,
                            gradient: gradient,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedBarChart extends StatelessWidget {
  const _GroupedBarChart({
    required this.months,
    required this.series,
    required this.maxAbsY,
  });

  final List<String> months;
  final List<_ChartSeries> series;
  final double maxAbsY;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    final double chartHeight = isTablet ? 230 : 180;
    final double rowLabelWidth = isTablet ? 56 : 46;
    final double minPlotWidth = isTablet ? 760 : 580;

    return Column(
      children: [
        SizedBox(
          height: chartHeight + 26,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: rowLabelWidth,
                height: chartHeight,
                child: _YAxisLabels(
                  maxY: maxAbsY,
                  steps: 4,
                  formatCompact: true,
                  negativeMin: -maxAbsY * 0.4,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: minPlotWidth,
                    child: _PlotArea(
                      months: months,
                      maxY: maxAbsY,
                      chartHeight: chartHeight,
                      negativeMin: -maxAbsY * 0.4,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List<Widget>.generate(months.length, (
                          int mi,
                        ) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 4 : 2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: List<Widget>.generate(series.length, (
                                  int si,
                                ) {
                                  final s = series[si];
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1.8,
                                      ),
                                      child: _SignedBar(
                                        month: months[mi],
                                        seriesName: s.label,
                                        value: s.data[mi],
                                        maxY: maxAbsY,
                                        negativeMin: -maxAbsY * 0.4,
                                        gradient:
                                            AppColors.buildPrimaryGradient(
                                              colors: s.gradientColors,
                                            ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: series
              .map(
                (item) => _LegendDot(
                  label: item.label,
                  gradient: AppColors.buildPrimaryGradient(
                    colors: item.gradientColors,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PlotArea extends StatelessWidget {
  const _PlotArea({
    required this.months,
    required this.maxY,
    required this.chartHeight,
    required this.child,
    this.negativeMin = 0,
  });

  final List<String> months;
  final double maxY;
  final double chartHeight;
  final Widget child;
  final double negativeMin;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    final double totalRange = maxY - negativeMin;
    final double zeroRatio = totalRange == 0 ? 1 : (maxY / totalRange);

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: List<Widget>.generate(5, (int index) {
                  return Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE9E8EF), width: 1),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (negativeMin < 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: chartHeight * (1 - zeroRatio),
                  child: Container(height: 1.2, color: const Color(0xFFCFCAD8)),
                ),
              child,
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List<Widget>.generate(months.length, (int index) {
            return Expanded(
              child: Text(
                months[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: isTablet ? 12 : 10.5,
                  color: AppColors.billingTextColor.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SingleBar extends StatelessWidget {
  const _SingleBar({
    required this.month,
    required this.value,
    required this.maxY,
    required this.gradient,
  });

  final String month;
  final double value;
  final double maxY;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final double barRatio = maxY == 0 ? 0 : (value / maxY).clamp(0.0, 1.0);
    final NumberFormatHelper formatter = NumberFormatHelper();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double h = constraints.maxHeight * barRatio;
        return Tooltip(
          message: '$month: ${formatter.currency(value)}',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: h < 2 && value > 0 ? 2 : h,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignedBar extends StatelessWidget {
  const _SignedBar({
    required this.month,
    required this.seriesName,
    required this.value,
    required this.maxY,
    required this.negativeMin,
    required this.gradient,
  });

  final String month;
  final String seriesName;
  final double value;
  final double maxY;
  final double negativeMin;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final double totalRange = maxY - negativeMin;
    final double zeroRatio = totalRange == 0 ? 1 : (maxY / totalRange);
    final NumberFormatHelper formatter = NumberFormatHelper();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double zeroY = constraints.maxHeight * (1 - zeroRatio);
        final double topArea = zeroY;
        final double bottomArea = constraints.maxHeight - zeroY;

        final Widget barContent;
        if (value >= 0) {
          final double ratio = maxY == 0 ? 0 : (value / maxY).clamp(0.0, 1.0);
          final double height = topArea * ratio;
          barContent = Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomArea,
                height: height < 2 && value > 0 ? 2 : height,
                child: _GradientBar(gradient: gradient),
              ),
            ],
          );
        } else {
          final double ratio = negativeMin == 0
              ? 0
              : (value.abs() / negativeMin.abs()).clamp(0.0, 1.0);
          final double height = bottomArea * ratio;
          barContent = Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: topArea,
                height: height < 2 && value.abs() > 0 ? 2 : height,
                child: _GradientBar(gradient: gradient),
              ),
            ],
          );
        }

        return Tooltip(
          message: '$month - $seriesName: ${formatter.currency(value)}',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: barContent,
          ),
        );
      },
    );
  }
}

class _GradientBar extends StatelessWidget {
  const _GradientBar({required this.gradient});

  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels({
    required this.maxY,
    required this.steps,
    this.negativeMin = 0,
    this.formatCompact = false,
  });

  final double maxY;
  final int steps;
  final double negativeMin;
  final bool formatCompact;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    final NumberFormatHelper formatter = NumberFormatHelper();
    final double range = maxY - negativeMin;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(steps + 1, (int index) {
        final double v = maxY - (range * (index / steps));
        return Text(
          formatCompact ? formatter.currencyCompact(v) : formatter.currency(v),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: isTablet ? 11 : 10,
            color: AppColors.billingTextColor.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
        );
      }),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.gradient});

  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: isTablet ? 12 : 11,
            fontWeight: FontWeight.w500,
            color: AppColors.billingTextColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _ChartSeries {
  const _ChartSeries({
    required this.label,
    required this.data,
    required this.gradientColors,
  });

  final String label;
  final List<double> data;
  final List<Color> gradientColors;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class NumberFormatHelper {
  String currency(double value) {
    final String sign = value < 0 ? '-' : '';
    final String abs = value.abs().toStringAsFixed(0);
    final String withCommas = abs.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$sign\$$withCommas';
  }

  String currencyCompact(double value) {
    final double abs = value.abs();
    final String sign = value < 0 ? '-' : '';
    if (abs >= 1000000) {
      return '$sign\$${(abs / 1000000).toStringAsFixed(abs >= 10000000 ? 0 : 1)}M';
    }
    if (abs >= 1000) {
      return '$sign\$${(abs / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}k';
    }
    return '$sign\$${abs.toStringAsFixed(0)}';
  }
}

double _maxValue(List<double> data) {
  if (data.isEmpty) return 1;
  double max = data.first;
  for (final double v in data) {
    if (v > max) max = v;
  }
  return max <= 0 ? 1 : max;
}
