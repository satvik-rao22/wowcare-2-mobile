import 'package:isar/isar.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';

part 'assessment_collection.g.dart';

/// Deterministic key for a scored record. Enforces the (studentId, milestoneId,
/// periodStart) uniqueness from PRD §17.1 so a `put` naturally upserts
/// (BR-AS-01) — re-assessing the same milestone in the same month replaces the
/// existing row instead of inserting a duplicate.
String assessmentKey(String studentId, String milestoneId, DateTime periodStart) {
  final ym =
      '${periodStart.year.toString().padLeft(4, '0')}-${periodStart.month.toString().padLeft(2, '0')}';
  return '$studentId#$milestoneId#$ym';
}

@collection
class AssessmentCollection {
  /// Derived from the composite key, not the entity id, to guarantee upsert.
  Id get isarId => fastHash(assessmentKey(studentId, milestoneId, periodStart));

  late String id;

  @Index()
  late String studentId;

  @Index()
  late String milestoneId;
  late String subdomainId;

  @Index()
  late String domainId;

  @Index()
  late String schoolId;

  late int score;
  String? notes;
  late String assessedBy;
  late DateTime assessedAt;

  @Index()
  late DateTime periodStart;
  late DateTime periodEnd;
  String? impersonatorId;

  AssessmentCollection();

  factory AssessmentCollection.fromEntity(Assessment assessment) {
    return AssessmentCollection()
      ..id = assessment.id
      ..studentId = assessment.studentId
      ..milestoneId = assessment.milestoneId
      ..subdomainId = assessment.subdomainId
      ..domainId = assessment.domainId
      ..schoolId = assessment.schoolId
      ..score = assessment.score
      ..notes = assessment.notes
      ..assessedBy = assessment.assessedBy
      ..assessedAt = assessment.assessedAt
      ..periodStart = assessment.periodStart
      ..periodEnd = assessment.periodEnd
      ..impersonatorId = assessment.impersonatorId;
  }

  Assessment toEntity() {
    return Assessment(
      id: id,
      studentId: studentId,
      milestoneId: milestoneId,
      subdomainId: subdomainId,
      domainId: domainId,
      score: score,
      notes: notes,
      assessedBy: assessedBy,
      assessedAt: assessedAt,
      periodStart: periodStart,
      periodEnd: periodEnd,
      schoolId: schoolId,
      impersonatorId: impersonatorId,
    );
  }
}
