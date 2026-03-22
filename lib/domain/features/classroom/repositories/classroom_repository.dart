import '../entities/classroom.dart';
import '../../student_classroom/entities/student_classroom_item.dart';

abstract class ClassroomRepository {
  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
    /// When true, restricts results to type=CLASSROOM.
    /// When false, omits the type filter.
    bool onlyTypeClassroom,
  });

  /// Returns students for a classroom via `GET /api/v1/student-classroom`.
  ///
  /// This is exposed under the Classroom feature as a convenience wrapper,
  /// while the underlying implementation uses the student-classroom repository
  /// (including cache via `CacheManager`).
  Future<List<StudentClassroomItem>> getClassroomStudents({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
    bool refresh,
  });
}

