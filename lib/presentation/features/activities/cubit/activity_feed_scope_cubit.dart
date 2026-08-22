import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/domain/features/activity/usecases/get_active_activity_types_for_school_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_daily_activity_feed_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_range_activity_feed_usecase.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart'
    hide StudentAttendanceTime;
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_absent_records_activity_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_daily_usecase.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_codes_for_activity_tag_filter_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student_classroom/entities/student_classroom_item.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/get_student_classroom_list_usecase.dart';
import 'package:wowcare/presentation/features/activities/utils/activity_filter_metadata_cache.dart';

part 'activity_feed_scope_state.dart';

/// Shared ViewModel for the activity feed screens (Daily + Custom range) —
/// classroom/tag/student-filter loading, feed fetching, and staff-name
/// resolution, all of which used to be resolved directly via `serviceLocator`
/// inside each View's State class. Each method here is a faithful pass-
/// through to the same use case/utility call the View made itself before —
/// behaviour is unchanged, only where the call is resolved from moves out of
/// the View (audit rule "Views call Cubits, not UseCases/DataSources").
/// The Views keep their own field/UI state; this is a stateless data facade,
/// same pattern as [ActivityEditorCubit].
class ActivityFeedScopeCubit extends Cubit<ActivityFeedScopeState> {
  ActivityFeedScopeCubit({
    required GetDailyActivityFeedUseCase getDailyActivityFeedUseCase,
    required GetRangeActivityFeedUseCase getRangeActivityFeedUseCase,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required GetActiveActivityTypesForSchoolUseCase
        getActiveActivityTypesForSchoolUseCase,
    required GetStudentClassroomListUseCase getStudentClassroomListUseCase,
    required GetTagNameCodeMapForSchoolUseCase
        getTagNameCodeMapForSchoolUseCase,
    required GetStudentCodesForActivityTagFilterUseCase
        getStudentCodesForActivityTagFilterUseCase,
    required GetStudentPageUseCase getStudentPageUseCase,
    required GetStudentAttendanceDailyUseCase getStudentAttendanceDailyUseCase,
    required GetStudentAbsentRecordsActivityUseCase
        getStudentAbsentRecordsActivityUseCase,
    required StaffRepository staffRepository,
    required StorageService storageService,
  })  : _getDailyActivityFeedUseCase = getDailyActivityFeedUseCase,
        _getRangeActivityFeedUseCase = getRangeActivityFeedUseCase,
        _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
        _getActiveActivityTypesForSchoolUseCase =
            getActiveActivityTypesForSchoolUseCase,
        _getStudentClassroomListUseCase = getStudentClassroomListUseCase,
        _getTagNameCodeMapForSchoolUseCase = getTagNameCodeMapForSchoolUseCase,
        _getStudentCodesForActivityTagFilterUseCase =
            getStudentCodesForActivityTagFilterUseCase,
        _getStudentPageUseCase = getStudentPageUseCase,
        _getStudentAttendanceDailyUseCase = getStudentAttendanceDailyUseCase,
        _getStudentAbsentRecordsActivityUseCase =
            getStudentAbsentRecordsActivityUseCase,
        _staffRepository = staffRepository,
        _cacheManager = CacheManager(storageService),
        super(const ActivityFeedScopeState());

  final GetDailyActivityFeedUseCase _getDailyActivityFeedUseCase;
  final GetRangeActivityFeedUseCase _getRangeActivityFeedUseCase;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final GetActiveActivityTypesForSchoolUseCase
      _getActiveActivityTypesForSchoolUseCase;
  final GetStudentClassroomListUseCase _getStudentClassroomListUseCase;
  final GetTagNameCodeMapForSchoolUseCase _getTagNameCodeMapForSchoolUseCase;
  final GetStudentCodesForActivityTagFilterUseCase
      _getStudentCodesForActivityTagFilterUseCase;
  final GetStudentPageUseCase _getStudentPageUseCase;
  final GetStudentAttendanceDailyUseCase _getStudentAttendanceDailyUseCase;
  final GetStudentAbsentRecordsActivityUseCase
      _getStudentAbsentRecordsActivityUseCase;
  final StaffRepository _staffRepository;
  final CacheManager _cacheManager;

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
  }) =>
      _getDailyActivityFeedUseCase(
        classroomCode: classroomCode,
        date: date,
        studentCode: studentCode,
        classroomCodes: classroomCodes,
        studentCodes: studentCodes,
        activityTypeCodes: activityTypeCodes,
        approvalStatuses: approvalStatuses,
        guardianPersona: guardianPersona,
        page: page,
        size: size,
      );

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
  }) =>
      _getRangeActivityFeedUseCase(
        classroomCode: classroomCode,
        startDate: startDate,
        endDate: endDate,
        studentCode: studentCode,
        classroomCodes: classroomCodes,
        studentCodes: studentCodes,
        activityTypeCodes: activityTypeCodes,
        approvalStatuses: approvalStatuses,
        guardianPersona: guardianPersona,
        page: page,
        size: size,
      );

  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
    bool onlyTypeClassroom = true,
    String? typeOverride,
  }) =>
      _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        onlyTypeClassroom: onlyTypeClassroom,
        typeOverride: typeOverride,
      );

  Future<List<ActivitySetting>> loadActivityTypeSettingsForFilters({
    required String schoolCode,
    bool forceRefresh = false,
  }) =>
      ActivityFilterMetadataCache.loadSchoolActivityTypeSettingsForFilters(
        cacheManager: _cacheManager,
        useCase: _getActiveActivityTypesForSchoolUseCase,
        schoolCode: schoolCode,
        forceRefresh: forceRefresh,
      );

  Future<List<StudentClassroomItem>> getStudentClassroomList({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? studentCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
    bool refresh = false,
  }) =>
      _getStudentClassroomListUseCase(
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        firstName: firstName,
        lastName: lastName,
        search: search,
        studentCodes: studentCodes,
        tagCodes: tagCodes,
        guardianCodes: guardianCodes,
        status: status,
        attendanceStatus: attendanceStatus,
        refresh: refresh,
      );

  Future<Map<String, String>> loadTagNameCodeMap({
    required String schoolCode,
    bool forceRefresh = false,
  }) =>
      ActivityFilterMetadataCache.loadTagNameCodeMap(
        cacheManager: _cacheManager,
        useCase: _getTagNameCodeMapForSchoolUseCase,
        schoolCode: schoolCode,
        forceRefresh: forceRefresh,
      );

  Future<List<String>> getStudentCodesForActivityTagFilter({
    required String schoolCode,
    required String classroomCode,
    required List<String> tagCodes,
  }) =>
      _getStudentCodesForActivityTagFilterUseCase(
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        tagCodes: tagCodes,
      );

  Future<StudentPage> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? attendanceStatuses,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? allowedClassroomCodes,
  }) =>
      _getStudentPageUseCase(
        schoolCode: schoolCode,
        code: code,
        firstName: firstName,
        lastName: lastName,
        status: status,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        guardianCodes: guardianCodes,
        attendanceStatuses: attendanceStatuses,
        search: search,
        page: page,
        size: size,
        allowedClassroomCodes: allowedClassroomCodes,
      );

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
  }) =>
      _getStudentAttendanceDailyUseCase(
        attendanceDate: attendanceDate,
        fromAttendanceDate: fromAttendanceDate,
        toAttendanceDate: toAttendanceDate,
        classroomCodes: classroomCodes,
        studentCodes: studentCodes,
        tagCodes: tagCodes,
        signInAtFilter: signInAtFilter,
        signOutAtFilter: signOutAtFilter,
        isExpectedNotMarked: isExpectedNotMarked,
        search: search,
        page: page,
        size: size,
      );

  Future<StudentAttendanceAbsentFormPage> getStudentAbsentRecordsActivity({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? studentCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) =>
      _getStudentAbsentRecordsActivityUseCase(
        fromAbsenceDate: fromAbsenceDate,
        toAbsenceDate: toAbsenceDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        studentCodes: studentCodes,
        search: search,
        page: page,
        size: size,
      );

  /// The logged-in staff member's own profile (primary/allowed classroom
  /// codes) — used to scope which classrooms this staff member may see.
  Future<StaffProfile> getOwnStaffProfileForClassroomScope({
    required String staffCode,
  }) =>
      _staffRepository.getStaffProfile(staffCode: staffCode, forEditStaff: true);

  /// Resolves display names for staff codes not already known to the
  /// caller. A code that fails to resolve is simply omitted from the
  /// result — best-effort, matching the original inline behaviour this
  /// replaces.
  Future<Map<String, String>> resolveStaffDisplayNames(
    Iterable<String> staffCodes,
  ) async {
    final result = <String, String>{};
    await Future.wait(
      staffCodes.map((code) async {
        try {
          final profile = await _staffRepository.getStaffProfile(
            staffCode: code,
          );
          final full = profile.fullName.trim();
          final composed = '${profile.firstName} ${profile.lastName}'.trim();
          final resolved = full.isNotEmpty ? full : composed;
          if (resolved.isNotEmpty) result[code] = resolved;
        } catch (_) {}
      }),
    );
    return result;
  }
}
