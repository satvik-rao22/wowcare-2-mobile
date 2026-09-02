import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
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

  /// Fresh school-timezone resolution — re-syncs the server clock at the
  /// moment it's called, per [SchoolTimezoneResolver]'s own "fetch fresh"
  /// contract.
  Future<String> resolveFreshSchoolTimeZone() {
    return SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storage,
      apiClient: _apiClient,
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
      _idempotencyKey ??= IdempotencyKey.generate();
      final result = await _submitStaffSignOut(
        request: request,
        isSelf: isSelf,
        idempotencyKey: _idempotencyKey,
      );
      if (!isClosed) emit(StaffSignOutSubmitSuccess(result));
      _idempotencyKey = null;
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(StaffSignOutSubmitFailure(ApiErrorHandler.extractErrorMessage(e)));
      }
      rethrow;
    }
  }
}
