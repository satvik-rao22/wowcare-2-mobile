import 'package:wowcare/domain/features/assessments/entities/assessment.dart';

/// JSON-serialisable DTO for a scored assessment record (PRD §17.1, §18.3).
class AssessmentModel {
  const AssessmentModel({
    required this.id,
    required this.studentId,
    required this.milestoneId,
    required this.subdomainId,
    required this.domainId,
    required this.score,
    this.notes,
    this.assessedBy = '',
    required this.assessedAt,
    required this.periodStart,
    required this.periodEnd,
    this.ageGroupId = '',
    this.schoolId = '',
    this.impersonatorId,
    this.published = false,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    DateTime parse(dynamic raw, DateTime fallback) =>
        DateTime.tryParse(raw?.toString() ?? '') ?? fallback;
    final start = parse(json['periodStart'], DateTime(now.year, now.month, 1));
    return AssessmentModel(
      id: (json['id'] ?? '').toString().trim(),
      studentId: (json['studentId'] ?? '').toString().trim(),
      milestoneId: (json['milestoneId'] ?? '').toString().trim(),
      subdomainId: (json['subdomainId'] ?? '').toString().trim(),
      domainId: (json['domainId'] ?? '').toString().trim(),
      score: int.tryParse((json['score'] ?? '').toString()) ?? 0,
      notes: json['notes']?.toString(),
      assessedBy: (json['assessedBy'] ?? '').toString(),
      assessedAt: parse(json['assessedAt'], now),
      periodStart: start,
      periodEnd: parse(
        json['periodEnd'],
        DateTime(start.year, start.month + 1, 0),
      ),
      ageGroupId: (json['ageGroupId'] ?? '').toString().trim(),
      schoolId: (json['schoolId'] ?? '').toString(),
      impersonatorId: json['impersonatorId']?.toString(),
      published: json['published'] == true,
    );
  }

  final String id;
  final String studentId;
  final String milestoneId;
  final String subdomainId;
  final String domainId;
  final int score;
  final String? notes;
  final String assessedBy;
  final DateTime assessedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String ageGroupId;
  final String schoolId;
  final String? impersonatorId;
  final bool published;

  Assessment toEntity() => Assessment(
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
        ageGroupId: ageGroupId,
        schoolId: schoolId,
        impersonatorId: impersonatorId,
        published: published,
      );
}
