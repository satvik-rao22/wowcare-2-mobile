import 'package:isar/isar.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';

part 'assessment_reference_collection.g.dart';

/// Isar persistence for the classroom/student reference snapshots the module
/// seeds while the backend is offline.
@collection
class AssessmentClassroomCollection {
  Id get isarId => fastHash(code);

  @Index(unique: true, replace: true)
  late String code;

  @Index()
  late String schoolId;
  late String name;
  late String ageGroup;

  AssessmentClassroomCollection();

  factory AssessmentClassroomCollection.fromEntity(AssessmentClassroom c) {
    return AssessmentClassroomCollection()
      ..code = c.code
      ..schoolId = c.schoolId
      ..name = c.name
      ..ageGroup = c.ageGroup;
  }

  AssessmentClassroom toEntity() => AssessmentClassroom(
        code: code,
        name: name,
        ageGroup: ageGroup,
        schoolId: schoolId,
      );
}

@collection
class AssessmentStudentCollection {
  Id get isarId => fastHash(code);

  @Index(unique: true, replace: true)
  late String code;

  @Index()
  late String classroomCode;

  @Index()
  late String schoolId;
  late String name;
  String? avatarUrl;
  late String status;
  List<String> tags = const <String>[];

  AssessmentStudentCollection();

  factory AssessmentStudentCollection.fromEntity(AssessmentStudent s) {
    return AssessmentStudentCollection()
      ..code = s.code
      ..classroomCode = s.classroomCode
      ..schoolId = s.schoolId
      ..name = s.name
      ..avatarUrl = s.avatarUrl
      ..status = s.status
      ..tags = s.tags;
  }

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
