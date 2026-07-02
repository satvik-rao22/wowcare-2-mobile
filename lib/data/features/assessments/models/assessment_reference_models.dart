import 'package:wowcare/domain/features/assessments/entities/assessment_age_group.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';

/// JSON DTOs for the classroom/student/age-group reference snapshots the
/// Assessments module seeds while the backend is offline (see
/// [AssessmentClassroom] / [AssessmentStudent] / [AssessmentAgeGroup] for the
/// rationale).

class AssessmentAgeGroupModel {
  const AssessmentAgeGroupModel({
    required this.id,
    required this.name,
    required this.minMonths,
    required this.maxMonths,
    this.sortOrder = 0,
    this.active = true,
    this.schoolId = '',
  });

  factory AssessmentAgeGroupModel.fromJson(Map<String, dynamic> json) =>
      AssessmentAgeGroupModel(
        id: (json['id'] ?? '').toString().trim(),
        name: (json['name'] ?? '').toString(),
        minMonths: int.tryParse((json['minMonths'] ?? '').toString()) ?? 0,
        maxMonths: int.tryParse((json['maxMonths'] ?? '').toString()) ?? 0,
        sortOrder: int.tryParse((json['sortOrder'] ?? '').toString()) ?? 0,
        active: json['active'] != false,
        schoolId: (json['schoolId'] ?? '').toString(),
      );

  final String id;
  final String name;
  final int minMonths;
  final int maxMonths;
  final int sortOrder;
  final bool active;
  final String schoolId;

  AssessmentAgeGroup toEntity() => AssessmentAgeGroup(
        id: id,
        name: name,
        minMonths: minMonths,
        maxMonths: maxMonths,
        sortOrder: sortOrder,
        active: active,
        schoolId: schoolId,
      );
}

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
    this.dateOfBirth,
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
        dateOfBirth: DateTime.tryParse(
            (json['dateOfBirth'] ?? json['dob'] ?? '').toString()),
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
  final DateTime? dateOfBirth;
  final String? avatarUrl;
  final String status;
  final String schoolId;
  final List<String> tags;

  AssessmentStudent toEntity() => AssessmentStudent(
        code: code,
        name: name,
        classroomCode: classroomCode,
        dateOfBirth: dateOfBirth,
        avatarUrl: avatarUrl,
        status: status,
        schoolId: schoolId,
        tags: tags,
      );
}
