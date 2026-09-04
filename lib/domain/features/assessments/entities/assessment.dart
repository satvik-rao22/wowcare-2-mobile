import 'package:equatable/equatable.dart';

/// A scored observation linking a Student, a Milestone, and a 1–5 rating for a
/// given assessment period (PRD §4 glossary, §17.1 data model).
///
/// Records are unique on (studentId, milestoneId, periodStart) and upserted on
/// save (PRD BR-AS-01): re-assessing the same milestone in the same period
/// replaces the existing score and notes rather than creating a new row.
class Assessment extends Equatable {
  const Assessment({
    required this.id,
    required this.studentId,
    required this.milestoneId,
    required this.subdomainId,
    required this.domainId,
    required this.score,
    this.notes,
    required this.assessedBy,
    required this.assessedAt,
    required this.periodStart,
    required this.periodEnd,
    this.ageGroupId = '',
    this.schoolId = '',
    this.impersonatorId,
    this.published = false,
  });

  final String id;
  final String studentId;
  final String milestoneId;
  final String subdomainId;
  final String domainId;

  /// The age band the child was in when scored (resolved from their date of
  /// birth at [periodStart] and stamped at save time). Freezes history: later
  /// edits to the school's bands never reinterpret this record.
  final String ageGroupId;

  /// Integer 1–5 (VR-AS-01/02).
  final int score;

  /// Optional free text, max 500 chars (VR-AS-03).
  final String? notes;
  final String assessedBy;
  final DateTime assessedAt;

  /// First day of the assessment-period month (UTC midnight).
  final DateTime periodStart;

  /// Last day of the assessment-period month.
  final DateTime periodEnd;
  final String schoolId;

  /// Set only when a CWW Super Admin acted via impersonation (PRD §19).
  final String? impersonatorId;

  /// Whether this record has been published to make the assessment visible
  /// as finalized. Set on every record for a student+period together.
  final bool published;

  Assessment copyWith({
    String? id,
    String? studentId,
    String? milestoneId,
    String? subdomainId,
    String? domainId,
    int? score,
    String? Function()? notes,
    String? assessedBy,
    DateTime? assessedAt,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? ageGroupId,
    String? schoolId,
    String? Function()? impersonatorId,
    bool? published,
  }) {
    return Assessment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      milestoneId: milestoneId ?? this.milestoneId,
      subdomainId: subdomainId ?? this.subdomainId,
      domainId: domainId ?? this.domainId,
      score: score ?? this.score,
      notes: notes != null ? notes() : this.notes,
      assessedBy: assessedBy ?? this.assessedBy,
      assessedAt: assessedAt ?? this.assessedAt,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      ageGroupId: ageGroupId ?? this.ageGroupId,
      schoolId: schoolId ?? this.schoolId,
      impersonatorId:
          impersonatorId != null ? impersonatorId() : this.impersonatorId,
      published: published ?? this.published,
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        milestoneId,
        score,
        notes,
        periodStart,
        ageGroupId,
        assessedAt,
        published,
      ];
}

/// A calendar-month assessment window selected via the MonthPicker (PRD §4).
/// Assessments are filtered and aggregated by period.
class AssessmentPeriod extends Equatable {
  const AssessmentPeriod({required this.start, required this.end});

  /// Builds the period covering the month containing [date], normalised to the
  /// 1st (start) and last day (end) of that month at local midnight.
  factory AssessmentPeriod.forMonth(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    // Day 0 of the next month is the last day of this month.
    final end = DateTime(date.year, date.month + 1, 0);
    return AssessmentPeriod(start: start, end: end);
  }

  /// The current calendar month.
  factory AssessmentPeriod.current() => AssessmentPeriod.forMonth(DateTime.now());

  final DateTime start;
  final DateTime end;

  /// The period immediately preceding this one (used for radar comparison —
  /// PRD BR-CA-02). Always the prior calendar month.
  AssessmentPeriod get previous =>
      AssessmentPeriod.forMonth(DateTime(start.year, start.month - 1, 1));

  /// True when [date] falls within this period (inclusive).
  bool contains(DateTime date) =>
      !date.isBefore(start) &&
      date.isBefore(DateTime(end.year, end.month, end.day + 1));

  /// Whether this period is in the future relative to [now] (VR-MP-01:
  /// assessing a future period is blocked).
  bool isFuture([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final currentMonthStart = DateTime(ref.year, ref.month, 1);
    return start.isAfter(currentMonthStart);
  }

  @override
  List<Object?> get props => [start, end];
}
