import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/idempotency_key.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_out_request.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_sign_out_usecase.dart';

import 'student_sign_out_submit_state.dart';

/// Owns the student sign-out submit call and its in-progress/success/failure
/// state, routing the mutation through [SubmitStudentSignOutUseCase] instead of
/// the View touching [AttendanceRepository] directly.
///
/// [submit] intentionally RETURNS the [AttendanceActionResult] and RETHROWS on
/// error: this refactor moves the repository call behind the UseCase and
/// centralises submit state, but the form keeps its exact success/navigation
/// and catch behaviour, so nothing the user sees changes.
class StudentSignOutSubmitCubit extends Cubit<StudentSignOutSubmitState> {
  StudentSignOutSubmitCubit(
    this._submitStudentSignOut, {
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _storage = storageService,
       _apiClient = apiClient,
       super(const StudentSignOutSubmitInitial());

  final SubmitStudentSignOutUseCase _submitStudentSignOut;
  final StorageService _storage;
  final ApiClient _apiClient;

  String? _idempotencyKey;

  // The request the current _idempotencyKey was minted for. A resubmit
  // with an UNCHANGED request reuses the key (protects a genuine retry,
  // e.g. after a timeout, from double-submitting); a DIFFERENT request
  // (corrected payload) gets a fresh key instead of silently replaying
  // whatever the backend's idempotency layer cached for the first one.
  Object? _idempotencyKeyRequest;

  /// Fresh school-timezone resolution — re-syncs the server clock at the
  /// moment it's called, per [SchoolTimezoneResolver]'s own "fetch fresh"
  /// contract. Used by the View both to seed date/time on load and again
  /// (fresh) right before submit.
  Future<String> resolveFreshSchoolTimeZone() {
    return SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storage,
      apiClient: _apiClient,
    );
  }

  /// True while a submit is in flight.
  bool get isSubmitting => state is StudentSignOutSubmitInProgress;

  /// True for any staff-side login (school/org admin or regular staff);
  /// false for guardian/parent and kiosk-PIN access. Gates date/time editing.
  Future<bool> resolveIsStaffPersona() =>
      resolveIsStaffPersonaFromStorage(_storage);

  Future<AttendanceActionResult> submit({
    required StudentSignOutRequest request,
    required bool isParent,
  }) async {
    emit(const StudentSignOutSubmitInProgress());
    try {
      if (_idempotencyKey == null || _idempotencyKeyRequest != request) {
        _idempotencyKey = IdempotencyKey.generate();
        _idempotencyKeyRequest = request;
      }
      final result = await _submitStudentSignOut(
        request: request,
        isParent: isParent,
        idempotencyKey: _idempotencyKey,
      );
      if (!isClosed) emit(StudentSignOutSubmitSuccess(result));
      _idempotencyKey = null;
      _idempotencyKeyRequest = null;
      return result;
    } catch (e, st) {
      if (!isClosed) {
        emit(
          StudentSignOutSubmitFailure(ApiErrorHandler.extractErrorMessage(e)),
        );
      }
      AppLogger.recordError(
        e,
        st,
        reason: 'attendance.student_sign_out.submit',
      );
      rethrow;
    }
  }
}
