import '../entities/student_classroom_item.dart';

abstract class StudentClassroomRepository {
  /// Returns students for a classroom via
  /// `GET /api/v1/student-classroom`.
  ///
  /// [status] is an array param (e.g. ['ACTIVE']).
  /// [attendanceStatus] is a single value (e.g. 'SIGNED_IN').
  /// When [refresh] is true the repository should bypass cache.
  Future<List<StudentClassroomItem>> getStudentClassroomList({
    required String schoolCode,
    required String classroomCode,
    List<String>? tagCodes,
    List<String>? status,
    String? attendanceStatus,
    bool refresh,
  });
}


