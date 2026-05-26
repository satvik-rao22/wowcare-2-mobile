import '../entities/classroom.dart';
import '../entities/classroom_details.dart';
import '../../student_classroom/entities/student_classroom_item.dart';

abstract class ClassroomRepository {
  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
    /// When true, restricts results to type=CLASSROOM.
    /// When false, omits the type filter.
    bool onlyTypeClassroom,
    /// Overrides [onlyTypeClassroom] when non-null. Sets `type=<value>` on
    /// the request, used to fetch a specific non-CLASSROOM type (e.g. ADMIN).
    String? typeOverride,
  });

  Future<ClassroomDetails> getClassroomByCode({
    required String code,
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

