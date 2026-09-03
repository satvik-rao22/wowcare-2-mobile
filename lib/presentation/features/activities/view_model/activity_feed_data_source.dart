import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';

/// Narrow data seam for the daily/range activity feed — exactly the five
/// calls [ActivityFeedCubit] needs to run a tri-source daily or range load
/// plus staff-name priming. Kept deliberately small so it can be faked by
/// hand in unit tests (no mocktail, no full-Cubit surface to stub).
///
/// [ActivityFeedScopeCubit] already exposes these five methods with these
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

  /// Range-scoped counterpart of [getDailyActivityFeed] — same filters, but
  /// bounded by [startDate]/[endDate] instead of a single [getDailyActivityFeed]
  /// `date`. Backs `ActivityFeedCubit.loadRange`, the data-layer counterpart of
  /// `activity_custom_tab.dart`'s `_loadRangeFeed`/`_loadNextRangeFeedPage`.
  Future<ActivityFeedPage> getRangeActivityFeed({
    required String classroomCode,
    required String startDate,
    required String endDate,
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
