import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/idempotency_key.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_out_request.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_sign_out_usecase.dart';

import 'staff_sign_out_submit_state.dart';

/// Owns the staff sign-out submit call and its in-progress/success/failure
/// state, routing the mutation through [SubmitStaffSignOutUseCase] instead of
/// the View touching [AttendanceRepository] directly.
///
/// [submit] intentionally RETURNS the [AttendanceActionResult] and RETHROWS on
/// error: this refactor moves the repository call behind the UseCase and
/// centralises submit state, but the form keeps its exact success/navigation
/// and catch behaviour, so nothing the user sees changes.
class StaffSignOutSubmitCubit extends Cubit<StaffSignOutSubmitState> {
  StaffSignOutSubmitCubit(
    this._submitStaffSignOut, {
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _storage = storageService,
       _apiClient = apiClient,
       super(const StaffSignOutSubmitInitial());

  final SubmitStaffSignOutUseCase _submitStaffSignOut;
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
  /// contract.
  Future<String> resolveFreshSchoolTimeZone() {
    return SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storage,
      apiClient: _apiClient,
    );
  }

  /// Resolves the logged-in staff member's own staff code from storage.
  Future<String> resolveCurrentStaffCode() async {
    return (await _storage.getString(StorageKeys.staffCode) ?? '').trim();
  }

  /// Resolves the logged-in staff member's display name/designation from
  /// storage — used as a last-resort fallback to build a [StaffEntity] when
  /// none was passed in and none was found in the staff list.
  Future<({String staffCode, String displayName, String designation})>
  resolveCurrentStaffDisplay() async {
    final staffCode = await resolveCurrentStaffCode();
    final displayName =
        (await _storage.getString(StorageKeys.displayName) ?? '').trim();
    final designation =
        (await _storage.getString(StorageKeys.staffDesignation) ?? '').trim();
    return (
      staffCode: staffCode,
      displayName: displayName,
      designation: designation,
    );
  }

  /// True while a submit is in flight.
  bool get isSubmitting => state is StaffSignOutSubmitInProgress;

  Future<AttendanceActionResult> submit({
    required StaffSignOutRequest request,
    bool isSelf = false,
  }) async {
    emit(const StaffSignOutSubmitInProgress());
    try {
      if (_idempotencyKey == null || _idempotencyKeyRequest != request) {
        _idempotencyKey = IdempotencyKey.generate();
        _idempotencyKeyRequest = request;
      }
      final result = await _submitStaffSignOut(
        request: request,
        isSelf: isSelf,
        idempotencyKey: _idempotencyKey,
      );
      if (!isClosed) emit(StaffSignOutSubmitSuccess(result));
      _idempotencyKey = null;
      _idempotencyKeyRequest = null;
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(StaffSignOutSubmitFailure(ApiErrorHandler.extractErrorMessage(e)));
      }
      rethrow;
    }
  }
}
