import 'package:wowcare/domain/features/scheduling/entities/scheduling_block_status_kind.dart';

/// Staffing-ratio compliance rules: how the forecast API's `blockStatus`
/// string, and the scheduled-vs-required staff counts, resolve to a
/// [SchedulingBlockStatusKind].
///
/// These are business rules, not styling. They previously sat inside
/// `presentation/features/scheduling/utils/scheduling_block_status_style.dart`
/// — a 590-line file that also returned `Widget`s — so the domain layer could
/// not reach them and they could not be unit-tested without Flutter. The colour,
/// icon and label choices that *render* a kind stay in presentation; only the
/// decision of which kind applies lives here.
abstract final class SchedulingBlockStatusRules {
  SchedulingBlockStatusRules._();

  /// Maps forecast API `blockStatus` to a ratio kind. When [blockStatus] is
  /// non-empty, counts are not used (API status is authoritative).
  static SchedulingBlockStatusKind parseKind(
    String? blockStatus, {
    int scheduledStaff = 0,
    int requiredStaff = 0,
  }) {
    final raw = blockStatus?.trim().toUpperCase() ?? '';
    if (raw.isEmpty) {
      return _kindFromCounts(scheduledStaff, requiredStaff);
    }
    switch (raw) {
      case 'IN_RATIO':
      case 'IN RATIO':
      case 'INRATIO':
        return SchedulingBlockStatusKind.inRatio;
      case 'UNDER_RATIO':
      case 'UNDER RATIO':
      case 'UNDERRATIO':
      case 'NOT_IN_RATIO':
      case 'NOT IN RATIO':
        return SchedulingBlockStatusKind.underRatio;
      case 'EXTRA_STAFF':
      case 'EXTRA STAFF':
      case 'OVER_STAFF':
      case 'OVER STAFF':
      case 'OVER_RATIO':
      case 'OVER RATIO':
        return SchedulingBlockStatusKind.extraStaff;
    }
    if (_matchesUnder(raw)) return SchedulingBlockStatusKind.underRatio;
    if (_matchesExtra(raw)) return SchedulingBlockStatusKind.extraStaff;
    if (_matchesIn(raw)) return SchedulingBlockStatusKind.inRatio;
    return _kindFromCounts(scheduledStaff, requiredStaff);
  }

  static bool _matchesUnder(String raw) =>
      raw.contains('UNDER') ||
      raw.contains('BELOW') ||
      raw.contains('NOT_IN') ||
      raw.contains('NOT IN');

  /// Avoid `contains('OVER')` — it is not a substring of `IN_RATIO`, but
  /// explicit enums are matched first; fallbacks use prefixed tokens only.
  static bool _matchesExtra(String raw) =>
      raw.contains('EXTRA_STAFF') ||
      raw.contains('EXTRA STAFF') ||
      raw.contains('OVER_STAFF') ||
      raw.contains('OVER STAFF') ||
      raw.contains('OVER_RATIO') ||
      raw.contains('OVER RATIO') ||
      raw.startsWith('EXTRA_') ||
      raw.startsWith('OVER_');

  static bool _matchesIn(String raw) =>
      raw.contains('IN_RATIO') ||
      raw == 'IN' ||
      raw.contains('IN RATIO') ||
      raw.contains('OK');

  /// PRD Use Case 6: derive block kind from scheduled vs required staff.
  static SchedulingBlockStatusKind kindFromPrdCounts({
    required int scheduledStaff,
    required int requiredStaff,
    bool withinMonitoringWindow = true,
  }) {
    if (!withinMonitoringWindow) return SchedulingBlockStatusKind.empty;
    if (scheduledStaff < requiredStaff) {
      return SchedulingBlockStatusKind.underRatio;
    }
    if (scheduledStaff > requiredStaff) {
      return SchedulingBlockStatusKind.extraStaff;
    }
    return SchedulingBlockStatusKind.inRatio;
  }

  static SchedulingBlockStatusKind _kindFromCounts(
    int scheduled,
    int required,
  ) =>
      kindFromPrdCounts(
        scheduledStaff: scheduled,
        requiredStaff: required,
      );
}
