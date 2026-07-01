import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';

/// JSON DTOs for the classroom/student reference snapshots the Assessments
/// module seeds while the backend is offline (see [AssessmentClassroom] /
/// [AssessmentStudent] for the rationale).

class AssessmentClassroomModel {
  const AssessmentClassroomModel({
    required this.code,
    required this.name,
    this.ageGroup = '',
    this.schoolId = '',
  });

  factory AssessmentClassroomModel.fromJson(Map<String, dynamic> json) =>
      AssessmentClassroomModel(
        code: (json['code'] ?? json['id'] ?? '').toString().trim(),
        name: (json['name'] ?? '').toString(),
        ageGroup: (json['ageGroup'] ?? '').toString(),
        schoolId: (json['schoolId'] ?? '').toString(),
      );

  final String code;
  final String name;
  final String ageGroup;
  final String schoolId;

  AssessmentClassroom toEntity() => AssessmentClassroom(
        code: code,
        name: name,
        ageGroup: ageGroup,
        schoolId: schoolId,
      );
}

class AssessmentStudentModel {
  const AssessmentStudentModel({
    required this.code,
    required this.name,
    required this.classroomCode,
    this.avatarUrl,
    this.status = 'ACTIVE',
    this.schoolId = '',
    this.tags = const <String>[],
  });

  factory AssessmentStudentModel.fromJson(Map<String, dynamic> json) =>
      AssessmentStudentModel(
        code: (json['code'] ?? json['id'] ?? '').toString().trim(),
        name: (json['name'] ?? '').toString(),
        classroomCode:
            (json['classroomCode'] ?? json['classroomId'] ?? '').toString().trim(),
        avatarUrl: json['avatar']?.toString(),
        status: (json['status'] ?? 'ACTIVE').toString(),
        schoolId: (json['schoolId'] ?? '').toString(),
        tags: (json['tags'] as List<dynamic>? ?? const [])
            .map((t) => t.toString())
            .toList(),
      );

  final String code;
  final String name;
  final String classroomCode;
  final String? avatarUrl;
  final String status;
  final String schoolId;
  final List<String> tags;

  AssessmentStudent toEntity() => AssessmentStudent(
        code: code,
        name: name,
        classroomCode: classroomCode,
        avatarUrl: avatarUrl,
        status: status,
        schoolId: schoolId,
        tags: tags,
      );
}
