import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/attendance_classroom_scope.dart';
import 'package:wowcare/core/utils/attendance_cross_class_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_absent_toggle_query.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_profile_query.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_profile_absent_toggle_response.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_profile_response.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_staff_attendance_profile_absent_toggle_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/fetch_staff_attendance_profile_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_profile_usecase.dart';

/// ViewModel seam for [StaffAttendanceProfile]. Thin by design: it wraps
/// every raw `serviceLocator<UseCase>()` call the View previously made
/// directly, with the same signatures and return types, so no transformation
/// or setState logic in the View had to change — only where the fetch calls
/// live. Mirrors [StudentAttendanceProfileFetchCubit]'s scope and reasoning:
/// [StaffAttendanceProfile] has no automated test coverage and is a legal
/// attendance record screen, so this migration is deliberately scoped to
/// relocating the fetch calls only (Mandate 5), not a full state-owning
/// rewrite.
class StaffAttendanceProfileFetchCubit {
  StaffAttendanceProfileFetchCubit({
    required GetStaffProfileUseCase getStaffProfileUseCase,
    required FetchStaffAttendanceProfileUseCase
    fetchStaffAttendanceProfileUseCase,
    required FetchStaffAttendanceProfileAbsentToggleUseCase
    fetchStaffAttendanceProfileAbsentToggleUseCase,
    required GetStaffTodaySignInStatusUseCase getStaffTodaySignInStatusUseCase,
    required StorageService storageService,
  }) : _getStaffProfileUseCase = getStaffProfileUseCase,
       _fetchStaffAttendanceProfileUseCase = fetchStaffAttendanceProfileUseCase,
       _fetchStaffAttendanceProfileAbsentToggleUseCase =
           fetchStaffAttendanceProfileAbsentToggleUseCase,
       _getStaffTodaySignInStatusUseCase = getStaffTodaySignInStatusUseCase,
       _storageService = storageService;

  final GetStaffProfileUseCase _getStaffProfileUseCase;
  final FetchStaffAttendanceProfileUseCase _fetchStaffAttendanceProfileUseCase;
  final FetchStaffAttendanceProfileAbsentToggleUseCase
  _fetchStaffAttendanceProfileAbsentToggleUseCase;
  final GetStaffTodaySignInStatusUseCase _getStaffTodaySignInStatusUseCase;
  final StorageService _storageService;

  /// Used by the header-identity fill-in when opened by code only.
  Future<StaffProfile> fetchStaffProfile({
    required String staffCode,
    bool forEditStaff = true,
  }) {
    return _getStaffProfileUseCase(
      staffCode: staffCode,
      forEditStaff: forEditStaff,
    );
  }

  /// Used by [_loadData] to scope the profile/absent-toggle queries.
  Future<List<String>> resolveAllowedClassroomCodes() {
    return resolveAttendanceAllowedClassroomCodes(storage: _storageService);
  }

  /// Used by [_loadData] for the present-day summary + records.
  Future<StaffAttendanceProfileResponse?> fetchProfileData({
    required AttendanceProfileQuery query,
  }) {
    return _fetchStaffAttendanceProfileUseCase(query: query);
  }

  /// Used by [_loadData] for the absent-days toggle list.
  Future<StaffAttendanceProfileAbsentToggleResponse?> fetchAbsentToggleData({
    required AttendanceProfileAbsentToggleQuery query,
  }) {
    return _fetchStaffAttendanceProfileAbsentToggleUseCase(query: query);
  }

  /// Used by [_loadTodayStatus] to gate the action menu.
  Future<String?> fetchTodayStatus({required String staffCode}) {
    return _getStaffTodaySignInStatusUseCase(staffCode: staffCode);
  }

  /// Resolves the school's `allowTeacherCrossClassAttendance` flag.
  Future<bool> resolveCrossClassEnabled() {
    return AttendanceCrossClassResolver.isEnabledForCurrentSchool(
      storage: _storageService,
    );
  }

  /// The active school role string from storage, or null when absent —
  /// used to detect a parent/guardian session without relying solely on
  /// the (possibly not-yet-resolved) RoleCubit.
  Future<String?> resolveActiveSchoolRole() async {
    final role =
        (await _storageService.getString(StorageKeys.activeSchoolRole) ?? '')
            .trim();
    return role.isEmpty ? null : role;
  }

  /// The logged-in staff member's own staff code, from storage only (no
  /// RoleCubit/network fallback — the View layers that on top when empty).
  Future<String> resolveStaffCodeFromStorage() async {
    return (await _storageService.getString(StorageKeys.staffCode) ?? '')
        .trim();
  }
}
