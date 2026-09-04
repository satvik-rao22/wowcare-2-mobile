import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';

/// Pure score-aggregation helpers (PRD §14.2, BR-CA-01).
///
/// Averaging rule: average = sum of scored records / count of scored records.
/// Students/records without a score for an item are EXCLUDED from both the
/// numerator and the denominator — they do NOT count as zero.
abstract final class AssessmentAggregation {
  const AssessmentAggregation._();

  /// Mean of the scores, or null when [records] is empty (renders as "—").
  static double? mean(Iterable<Assessment> records) {
    var sum = 0;
    var count = 0;
    for (final r in records) {
      sum += r.score;
      count++;
    }
    if (count == 0) return null;
    return sum / count;
  }

  /// Average across [records] for one domain.
  static double? domainAverage(Iterable<Assessment> records, String domainId) =>
      mean(records.where((r) => r.domainId == domainId));

  static double? subdomainAverage(
    Iterable<Assessment> records,
    String subdomainId,
  ) =>
      mean(records.where((r) => r.subdomainId == subdomainId));

  static double? milestoneAverage(
    Iterable<Assessment> records,
    String milestoneId,
  ) =>
      mean(records.where((r) => r.milestoneId == milestoneId));

  /// One radar axis per active domain comparing current vs previous period.
  /// Both series use the same domain-average formula (PRD FR-SC-11).
  static List<RadarDatum> radarData({
    required List<AssessmentDomain> activeDomains,
    required Iterable<Assessment> currentRecords,
    required Iterable<Assessment> previousRecords,
  }) {
    return activeDomains.map((domain) {
      return RadarDatum(
        domainId: domain.id,
        domainName: domain.name,
        current: domainAverage(currentRecords, domain.id) ?? 0,
        previous: domainAverage(previousRecords, domain.id) ?? 0,
      );
    }).toList();
  }

  /// Rounds to one decimal place (PRD FR-CA-09).
  static String formatAverage(double? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(1);
  }
}

/// A single radar-chart axis value.
class RadarDatum {
  const RadarDatum({
    required this.domainId,
    required this.domainName,
    required this.current,
    required this.previous,
  });

  final String domainId;
  final String domainName;
  final double current;
  final double previous;
}
