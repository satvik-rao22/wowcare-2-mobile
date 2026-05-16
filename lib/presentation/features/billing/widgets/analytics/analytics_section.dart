import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

class AnalyticsSection extends StatelessWidget {
  const AnalyticsSection({super.key});

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

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    final double sectionGap = isTablet ? 16 : 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnalyticsBarCard(
          title: 'Revenue (Net Paid)',
          ytdLabel: 'Revenue YTD',
          ytdAmount: 9000,
          data: const <double>[4000, 3000, 2000, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          gradient: AppColors.buildPrimaryGradient(
            colors: const <Color>[Color(0xFF1BB686), Color(0xFF31C9A5)],
          ),
          legendLabel: 'Revenue',
        ),
        SizedBox(height: sectionGap),
        _AnalyticsBarCard(
          title: 'Amount Invoiced',
          ytdLabel: 'Invoiced YTD',
          ytdAmount: 22000,
          data: const <double>[
            4000,
            3000,
            2000,
            0,
            8000,
            0,
            4000,
            0,
            0,
            0,
            1000,
            0,
          ],
          gradient: AppColors.buildPrimaryGradient(
            colors: const <Color>[Color(0xFF5A86FF), Color(0xFF3F7DE3)],
          ),
          legendLabel: 'Invoiced',
        ),
        SizedBox(height: sectionGap),
        _AnalyticsBarCard(
          title: 'Refunds',
          ytdLabel: 'Refunds YTD',
          ytdAmount: 13000,
          data: const <double>[
            1000,
            2000,
            0,
            0,
            1000,
            0,
            6000,
            0,
            0,
            0,
            0,
            3000,
          ],
          gradient: AppColors.buildPrimaryGradient(
            colors: const <Color>[Color(0xFFFF5A68), Color(0xFFEF3D4B)],
          ),
          legendLabel: 'Refunds',
        ),
        SizedBox(height: sectionGap),
        _SubsidiesOverviewCard(months: _months),
      ],
    );
  }
}

class _AnalyticsBarCard extends StatelessWidget {
  const _AnalyticsBarCard({
    required this.title,
    required this.ytdLabel,
    required this.ytdAmount,
    required this.data,
    required this.gradient,
    required this.legendLabel,
  });

  final String title;
  final String ytdLabel;
  final double ytdAmount;
  final List<double> data;
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
                      color: AppColors.billingTextColor.withOpacity(0.8),
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
                  Text(
                    '\u2191 \$0 vs last year',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 12 : 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFCC3948),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SimpleBarChart(
            data: data,
            months: AnalyticsSection._months,
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
                  color: AppColors.billingTextColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubsidiesOverviewCard extends StatelessWidget {
  const _SubsidiesOverviewCard({required this.months});

  final List<String> months;

  @override
  Widget build(BuildContext context) {
    final bool isTablet = ResponsiveSizing.isTablet(context);
    const List<double> balance = <double>[
      1000,
      4000,
      0,
      2000,
      1000,
      0,
      1000,
      0,
      0,
      0,
      -1000,
      0,
    ];
    const List<double> invoiced = <double>[
      1000,
      5000,
      0,
      3000,
      1000,
      0,
      1000,
      0,
      0,
      0,
      4000,
      0,
    ];
    const List<double> received = <double>[
      1000,
      1000,
      0,
      1000,
      1000,
      0,
      1000,
      0,
      0,
      0,
      5000,
      0,
    ];

    const double maxAbs = 5000;
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
                    'Subsidies Invoiced YTD',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.billingTextColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatter.currency(16000),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.billingTextColor,
                    ),
                  ),
                  Text(
                    '\u2191 \$0 vs last year',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: isTablet ? 12 : 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFCC3948),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GroupedBarChart(
            months: months,
            maxAbsY: maxAbs,
            series: const <_ChartSeries>[
              _ChartSeries(
                label: 'Balance',
                data: balance,
                gradientColors: <Color>[Color(0xFFFFC453), Color(0xFFFFA600)],
              ),
              _ChartSeries(
                label: 'Invoiced',
                data: invoiced,
                gradientColors: <Color>[Color(0xFF8E6EFF), Color(0xFF6A57E0)],
              ),
              _ChartSeries(
                label: 'Received',
                data: received,
                gradientColors: <Color>[Color(0xFF2BC7A2), Color(0xFF1CA482)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
                      final value = data[index];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 6 : 4,
                          ),
                          child: _SingleBar(
                            value: value,
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
                          int monthIndex,
                        ) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 4 : 2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: List<Widget>.generate(series.length, (
                                  int sIndex,
                                ) {
                                  final seriesItem = series[sIndex];
                                  final value = seriesItem.data[monthIndex];
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1.8,
                                      ),
                                      child: _SignedBar(
                                        value: value,
                                        maxY: maxAbsY,
                                        negativeMin: -maxAbsY * 0.4,
                                        gradient:
                                            AppColors.buildPrimaryGradient(
                                              colors: seriesItem.gradientColors,
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
                  color: AppColors.billingTextColor.withOpacity(0.75),
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
    required this.value,
    required this.maxY,
    required this.gradient,
  });

  final double value;
  final double maxY;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final double barRatio = maxY == 0 ? 0 : (value / maxY).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double h = constraints.maxHeight * barRatio;
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: h < 2 && value > 0 ? 2 : h,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

class _SignedBar extends StatelessWidget {
  const _SignedBar({
    required this.value,
    required this.maxY,
    required this.negativeMin,
    required this.gradient,
  });

  final double value;
  final double maxY;
  final double negativeMin;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final double totalRange = maxY - negativeMin;
    final double zeroRatio = totalRange == 0 ? 1 : (maxY / totalRange);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double zeroY = constraints.maxHeight * (1 - zeroRatio);
        final double topArea = zeroY;
        final double bottomArea = constraints.maxHeight - zeroY;

        if (value >= 0) {
          final double ratio = maxY == 0 ? 0 : (value / maxY).clamp(0.0, 1.0);
          final double height = topArea * ratio;
          return Stack(
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
        }

        final double ratio = negativeMin == 0
            ? 0
            : (value.abs() / negativeMin.abs()).clamp(0.0, 1.0);
        final double height = bottomArea * ratio;
        return Stack(
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
            color: AppColors.billingTextColor.withOpacity(0.6),
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
            color: AppColors.billingTextColor.withOpacity(0.8),
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
  if (data.isEmpty) return 0;
  double max = data.first;
  for (final double v in data) {
    if (v > max) max = v;
  }
  return max <= 0 ? 1 : max;
}
