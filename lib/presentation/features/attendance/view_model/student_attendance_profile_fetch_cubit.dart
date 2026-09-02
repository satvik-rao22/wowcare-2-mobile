import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_absent_toggle_query.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_query.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_profile_absent_toggle_response.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_profile_response.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_student_attendance_profile_absent_toggle_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_student_attendance_profile_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_out_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student/entities/student_profile.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';

/// ViewModel seam for [StudentAttendanceProfile]. Thin by design: it wraps
/// every raw `serviceLocator<UseCase>()` call the View previously made
/// directly, with the same signatures and return types, so no transformation
/// or setState logic in the View had to change — only where the fetch calls
/// live. [StudentAttendanceProfile] has no automated test coverage and is a
/// legal attendance record screen, so this migration is deliberately scoped
/// to relocating the fetch calls only (Mandate 5), not a full state-owning
/// rewrite; a fuller BlocBuilder conversion is left to a later pass once
/// characterization tests exist.
class StudentAttendanceProfileFetchCubit {
  StudentAttendanceProfileFetchCubit({
    required GetStudentProfileUseCase getStudentProfileUseCase,
    required GetStudentSignOutFormListUseCase getStudentSignOutFormListUseCase,
    required FetchStudentAttendanceProfileUseCase
    fetchStudentAttendanceProfileUseCase,
    required FetchStudentAttendanceProfileAbsentToggleUseCase
    fetchStudentAttendanceProfileAbsentToggleUseCase,
    required GetStudentTodaySignInStatusUseCase
    getStudentTodaySignInStatusUseCase,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StorageService storageService,
  }) : _getStudentProfileUseCase = getStudentProfileUseCase,
       _getStudentSignOutFormListUseCase = getStudentSignOutFormListUseCase,
       _fetchStudentAttendanceProfileUseCase =
           fetchStudentAttendanceProfileUseCase,
       _fetchStudentAttendanceProfileAbsentToggleUseCase =
           fetchStudentAttendanceProfileAbsentToggleUseCase,
       _getStudentTodaySignInStatusUseCase = getStudentTodaySignInStatusUseCase,
       _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _storageService = storageService;

  final GetStudentProfileUseCase _getStudentProfileUseCase;
  final GetStudentSignOutFormListUseCase _getStudentSignOutFormListUseCase;
  final FetchStudentAttendanceProfileUseCase
  _fetchStudentAttendanceProfileUseCase;
  final FetchStudentAttendanceProfileAbsentToggleUseCase
  _fetchStudentAttendanceProfileAbsentToggleUseCase;
  final GetStudentTodaySignInStatusUseCase _getStudentTodaySignInStatusUseCase;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StorageService _storageService;

  /// Used by [_ensureHeaderIdentityLoaded] to fill the header when opened by
  /// code only (notification deep-link).
  Future<StudentProfile> fetchStudentProfile({required String code}) {
    return _getStudentProfileUseCase(code: code);
  }

  /// Used by [_applyParentChildSelection] to resolve the selected child's
  /// current room/sign-in status for today.
  Future<StudentAttendanceCustomPage> fetchSignOutFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    int page = 0,
    int size = 10,
  }) {
    return _getStudentSignOutFormListUseCase(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      page: page,
      size: size,
    );
  }

  /// Used by [_loadData] to scope the profile/absent-toggle queries.
  Future<List<String>> resolveAllowedClassroomCodes() {
    return resolveStudentAttendanceAllowedClassroomCodes(
      storage: _storageService,
    );
  }

  /// Used by [_loadData] for the present-day summary + records.
  Future<StudentAttendanceProfileResponse?> fetchProfileData({
    required AttendanceProfileQuery query,
  }) {
    return _fetchStudentAttendanceProfileUseCase(query: query);
  }

  /// Used by [_loadData] for the absent-days toggle list.
  Future<StudentAttendanceProfileAbsentToggleResponse?> fetchAbsentToggleData({
    required AttendanceProfileAbsentToggleQuery query,
  }) {
    return _fetchStudentAttendanceProfileAbsentToggleUseCase(query: query);
  }

  /// Used by [_loadTodayStatus] to gate the action menu.
  Future<String?> fetchTodayStatus({required String studentCode}) {
    return _getStudentTodaySignInStatusUseCase(studentCode: studentCode);
  }

  /// Used by [_loadClassroomNameToCodeMap] for the classroom name<->code
  /// resolution shown in the header/action forms.
  Future<Map<String, String>> fetchClassroomNameToCodeMap() async {
    final schoolCode =
        await _storageService.getString(StorageKeys.schoolCode) ?? '';
    if (schoolCode.trim().isEmpty) return const <String, String>{};

    final classrooms = await _getActiveClassroomsUseCase(
      schoolCode: schoolCode,
      onlyTypeClassroom: true,
    );
    return {
      for (final c in classrooms)
        if (c.name.trim().isNotEmpty && c.code.trim().isNotEmpty)
          c.name: c.code,
    };
  }
}
