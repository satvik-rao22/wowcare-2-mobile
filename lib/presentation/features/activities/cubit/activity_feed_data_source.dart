import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';

/// Narrow data seam for the daily activity feed — exactly the four calls
/// [ActivityFeedCubit] needs to run a tri-source daily load plus staff-name
/// priming. Kept deliberately small so it can be faked by hand in unit tests
/// (no mocktail, no full-Cubit surface to stub).
///
/// [ActivityFeedScopeCubit] already exposes these four methods with these
/// signatures, so it `implements` this interface unchanged — production DI
/// passes the real scope cubit, tests pass a canned fake.
abstract class ActivityFeedDataSource {
  Future<ActivityFeedPage> getDailyActivityFeed({
    required String classroomCode,
    required String date,
    String? studentCode,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? activityTypeCodes,
    List<String>? approvalStatuses,
    bool guardianPersona = false,
    int page = 0,
    int size = 200,
  });

  Future<StudentAttendanceDailyPage> getStudentAttendanceDaily({
    required String attendanceDate,
    String? fromAttendanceDate,
    String? toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
  });

  Future<StudentAttendanceAbsentFormPage> getStudentAbsentRecordsActivity({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? studentCodes,
    String? search,
    int page = 0,
    int size = 10,
  });

  Future<Map<String, String>> resolveStaffDisplayNames(
    Iterable<String> staffCodes,
  );
}
