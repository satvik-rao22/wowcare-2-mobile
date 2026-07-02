import 'package:equatable/equatable.dart';

/// A school-defined developmental age band (e.g. "0–12 months").
///
/// Age groups replace classroom assignment as the visibility scope for the
/// parameter hierarchy: domains/subdomains/milestones are assigned to bands,
/// and a student's visible milestones are resolved from their date of birth —
/// not from the classroom they sit in (classrooms rarely align with the bands
/// standards frameworks use). Bands are half-open month ranges
/// `[minMonths, maxMonths)` so any age maps to at most one band.
///
/// A default set is seeded as the school's first preset; admins can edit it or
/// define fully custom bands (the school "owns" its bands).
class AssessmentAgeGroup extends Equatable {
  const AssessmentAgeGroup({
    required this.id,
    required this.name,
    required this.minMonths,
    required this.maxMonths,
    this.sortOrder = 0,
    this.active = true,
    this.schoolId = '',
  });

  final String id;
  final String name;

  /// Inclusive lower bound of the band, in months of age.
  final int minMonths;

  /// Exclusive upper bound of the band, in months of age.
  final int maxMonths;

  final int sortOrder;

  /// Soft-delete flag (deactivated bands keep their historical assessments).
  final bool active;
  final String schoolId;

  /// Whether an age of [ageMonths] falls inside this band.
  bool contains(int ageMonths) =>
      ageMonths >= minMonths && ageMonths < maxMonths;

  /// Whether this band's month range overlaps [other]'s (both half-open).
  bool overlaps(AssessmentAgeGroup other) =>
      minMonths < other.maxMonths && other.minMonths < maxMonths;

  /// Compact range label, e.g. "0–12m", "18–24m", "3–4y".
  String get rangeLabel {
    if (minMonths % 12 == 0 && maxMonths % 12 == 0 && minMonths >= 36) {
      return '${minMonths ~/ 12}–${maxMonths ~/ 12}y';
    }
    return '$minMonths–${maxMonths}m';
  }

  AssessmentAgeGroup copyWith({
    String? id,
    String? name,
    int? minMonths,
    int? maxMonths,
    int? sortOrder,
    bool? active,
    String? schoolId,
  }) {
    return AssessmentAgeGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      minMonths: minMonths ?? this.minMonths,
      maxMonths: maxMonths ?? this.maxMonths,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
      schoolId: schoolId ?? this.schoolId,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, minMonths, maxMonths, sortOrder, active, schoolId];
}
