import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';

/// Period-over-period radar comparison (PRD §12.3, FR-CA-10, FR-SC-05): current
/// month (indigo) vs previous month (yellow), one axis per domain.
///
/// Accessibility (PRD §21.4): the chart is wrapped in a [Semantics] node whose
/// label is a textual data table read by screen readers; a colour legend is
/// rendered below so the two series are distinguishable beyond colour alone.
/// A bar fallback is used when there are fewer than three domains (a radar
/// needs ≥ 3 axes).
class AssessmentRadarChart extends StatelessWidget {
  const AssessmentRadarChart({
    super.key,
    required this.title,
    required this.data,
    required this.currentLabel,
    required this.previousLabel,
  });

  final String title;
  final List<RadarDatum> data;
  final String currentLabel;
  final String previousLabel;

  static const Color _current = Color(0xFF6366F1);
  static const Color _previous = Color(0xFFEAB308);

  String get _semanticsSummary {
    final parts = data
        .map((d) => '${d.domainName}: '
            '$currentLabel ${d.current.toStringAsFixed(1)}, '
            '$previousLabel ${d.previous.toStringAsFixed(1)}')
        .join('. ');
    return '$title. $parts';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: Semantics(
              label: _semanticsSummary,
              child: data.length < 3
                  ? _BarFallback(
                      data: data,
                      current: _current,
                      previous: _previous,
                    )
                  : RadarChart(
                      RadarChartData(
                        radarShape: RadarShape.polygon,
                        radarBackgroundColor: Colors.transparent,
                        borderData: FlBorderData(show: false),
                        radarBorderData:
                            BorderSide(color: Colors.grey.shade200),
                        gridBorderData:
                            BorderSide(color: Colors.grey.shade200),
                        tickBorderData:
                            BorderSide(color: Colors.grey.shade100),
                        tickCount: 5,
                        ticksTextStyle:
                            const TextStyle(color: Colors.transparent, fontSize: 0),
                        titlePositionPercentageOffset: 0.18,
                        titleTextStyle: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                        getTitle: (index, angle) => RadarChartTitle(
                          text: index < data.length
                              ? data[index].domainName
                              : '',
                          angle: angle,
                        ),
                        dataSets: [
                          RadarDataSet(
                            dataEntries: data
                                .map((d) => RadarEntry(value: d.current))
                                .toList(),
                            borderColor: _current,
                            fillColor: _current.withValues(alpha: 0.28),
                            borderWidth: 2,
                            entryRadius: 2.5,
                          ),
                          RadarDataSet(
                            dataEntries: data
                                .map((d) => RadarEntry(value: d.previous))
                                .toList(),
                            borderColor: _previous,
                            fillColor: _previous.withValues(alpha: 0.18),
                            borderWidth: 2,
                            entryRadius: 2.5,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendDot(color: _current, label: currentLabel),
              _LegendDot(color: _previous, label: previousLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }
}

/// Grouped-bar fallback for 1–2 domains (radar requires ≥ 3 axes).
class _BarFallback extends StatelessWidget {
  const _BarFallback({
    required this.data,
    required this.current,
    required this.previous,
  });

  final List<RadarDatum> data;
  final Color current;
  final Color previous;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text('No data for this period',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.map((d) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.domainName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              _bar(d.current / 5, current,
                  AssessmentAggregation.formatAverage(d.current)),
              const SizedBox(height: 4),
              _bar(d.previous / 5, previous,
                  AssessmentAggregation.formatAverage(d.previous)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _bar(double fraction, Color color, String label) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
