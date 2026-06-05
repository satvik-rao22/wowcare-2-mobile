import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/domain/features/kiosk/usecases/sign_in_staff_usecase.dart';
import 'package:wowcare/domain/features/kiosk/usecases/sign_out_staff_usecase.dart';

part 'kiosk_attendance_state_v2.dart';

/// REFACTORED Kiosk Attendance Cubit using Clean Architecture + MVVM.
///
/// Responsibilities:
/// - Manage kiosk attendance state
/// - Orchestrate use cases
/// - Handle errors and loading states
/// - Emit immutable states
///
/// Does NOT:
/// - Directly call APIs
/// - Use Provider package
/// - Create duplicate instances
/// - Manage UI state directly
///
/// Uses:
/// - Domain layer use cases
/// - Proper state management
/// - BlocListener for UI reactions
class KioskAttendanceCubitV2 extends Cubit<KioskAttendanceStateV2> {
  KioskAttendanceCubitV2({
    required SignInStaffUseCase signInStaffUseCase,
    required SignOutStaffUseCase signOutStaffUseCase,
    required StorageService storageService,
    required ApiClient apiClient,
  })  : _signInStaffUseCase = signInStaffUseCase,
        _signOutStaffUseCase = signOutStaffUseCase,
        _storage = storageService,
        _apiClient = apiClient,
        super(const KioskAttendanceInitialV2()) {
    AppLogger.d('[Kiosk] KioskAttendanceCubitV2 initialized: CubitInitialized=true');
  }

  final SignInStaffUseCase _signInStaffUseCase;
  final SignOutStaffUseCase _signOutStaffUseCase;
  final StorageService _storage;
  final ApiClient _apiClient;

  /// Sign in staff member (KIOSK ONLY).
  ///
  /// Flow:
  /// 1. Get school timezone
  /// 2. Execute sign-in use case (calls sign-in API only)
  /// 3. Emit success state with status
  /// 4. BlocListener reacts to success
  /// 5. Navigate to /kiosk
  Future<void> signInStaff({
    required String staffCode,
    double latitude = 0,
    double longitude = 0,
    bool withinGeofence = true,
    String? pin,
  }) async {
    emit(const KioskAttendanceSubmittingV2());

    try {
      AppLogger.d('[KIOSK] Persona=STAFF');
      AppLogger.d('[KIOSK] StaffCode=$staffCode');
      AppLogger.d('[KIOSK] CallingStaffSignInApi=true');
      AppLogger.d('[KIOSK] Method=KIOSK');
      AppLogger.d('[KIOSK] PinIncluded=${pin?.isNotEmpty ?? false}');

      final schoolTimeZone =
          await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: _apiClient,
      );

      final result = await _signInStaffUseCase(
        staffCode: staffCode,
        timeZone: schoolTimeZone,
        latitude: latitude,
        longitude: longitude,
        withinGeofence: withinGeofence,
        pin: pin,
      );

      AppLogger.d('[KIOSK] AttendanceSuccess=true');
      AppLogger.d('[KIOSK] RedirectingTo=/kiosk');

      emit(KioskAttendanceSuccessV2(
        message: 'Signed in successfully',
        action: 'SIGN_IN',
        role: 'STAFF',
        staffCode: staffCode,
        status: result.status,
      ));
    } catch (e) {
      AppLogger.e('[KIOSK] AttendanceSuccess=false, error=$e');
      emit(KioskAttendanceErrorV2('Failed to sign in: $e'));
    }
  }

  /// Sign out staff member (KIOSK ONLY).
  Future<void> signOutStaff({
    required String staffCode,
    double latitude = 0,
    double longitude = 0,
    bool withinGeofence = true,
    String? pin,
  }) async {
    emit(const KioskAttendanceSubmittingV2());

    try {
      AppLogger.d('[KIOSK] Persona=STAFF');
      AppLogger.d('[KIOSK] StaffCode=$staffCode');
      AppLogger.d('[KIOSK] CallingStaffSignOutApi=true');
      AppLogger.d('[KIOSK] Method=KIOSK');
      AppLogger.d('[KIOSK] PinIncluded=${pin?.isNotEmpty ?? false}');

      final schoolTimeZone =
          await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: _apiClient,
      );

      final result = await _signOutStaffUseCase(
        staffCode: staffCode,
        timeZone: schoolTimeZone,
        latitude: latitude,
        longitude: longitude,
        withinGeofence: withinGeofence,
        pin: pin,
      );

      AppLogger.d('[KIOSK] AttendanceSuccess=true');
      AppLogger.d('[KIOSK] RedirectingTo=/kiosk');

      emit(KioskAttendanceSuccessV2(
        message: 'Signed out successfully',
        action: 'SIGN_OUT',
        role: 'STAFF',
        staffCode: staffCode,
        status: result.status,
      ));
    } catch (e) {
      AppLogger.e('[KIOSK] AttendanceSuccess=false, error=$e');
      emit(KioskAttendanceErrorV2('Failed to sign out: $e'));
    }
  }

  /// Reset to initial state (when returning to dashboard).
  void reset() {
    emit(const KioskAttendanceInitialV2());
  }
}
