import '../entities/classroom.dart';
import '../entities/classroom_details.dart';
import '../entities/ratio_monitoring_classroom.dart';
import '../entities/school_capacity.dart';
import '../entities/classroom_count.dart';
import '../entities/school_fte.dart';
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

  Future<SchoolCapacity> getSchoolCapacity({
    required String schoolCode,
  });

  Future<ClassroomCount> getClassroomCount({
    required String schoolCode,
    required String status,
  });

  Future<SchoolFte> getSchoolFte({
    required String schoolCode,
    required int capacity,
  });

  /// Returns paginated ACTIVE classrooms with capacity and ratio data.
  /// Used by the Ratio Monitoring dashboard card.
  Future<List<RatioMonitoringClassroom>> getRatioMonitoringClassrooms({
    required String schoolCode,
  });

  /// Per-classroom student attendance summary keyed by classroom code.
  Future<Map<String, ClassroomAttendanceSummaryEntry>>
  getStudentAttendanceSummaryByClassrooms({
    required List<String> classroomCodes,
    DateTime? date,
  });

  /// Per-classroom staff attendance summary keyed by classroom code.
  Future<Map<String, ClassroomAttendanceSummaryEntry>>
  getStaffAttendanceSummaryByClassrooms({
    required List<String> classroomCodes,
    DateTime? date,
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

  /// GET student-classroom enrolled count (active/upcoming/enrolled) for a
  /// classroom. Returns the raw backend response map.
  Future<Map<String, dynamic>?> getStudentClassroomEnrolledCount({
    required String classroomCode,
    String? organizationCode,
    String? schoolCode,
  });

  /// GET the logo asset codes list for a school's classrooms.
  Future<Map<String, dynamic>?> getClassroomLogoAssetCodes({
    required String classroomCode,
    required String schoolCode,
  });

  /// POST to create a classroom-logo upload session.
  Future<Map<String, dynamic>?> createClassroomLogoUploadSession({
    required String classroomCode,
    required String organizationCode,
    required String schoolCode,
  });

  /// POST to finalize a classroom logo with the uploaded [assetCode].
  Future<Map<String, dynamic>?> finalizeClassroomLogo({
    required String classroomCode,
    required String assetCode,
  });
}

