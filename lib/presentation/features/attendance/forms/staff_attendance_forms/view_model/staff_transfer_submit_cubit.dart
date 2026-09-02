import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_daily.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_transfer_request.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_transfer_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_transfer_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_profile_usecase.dart';

import 'staff_transfer_submit_state.dart';

/// Owns the staff transfer submit call and its in-progress/success/failure
/// state, routing the mutation through [SubmitStaffTransferUseCase] instead of
/// the View touching [AttendanceRepository] directly.
///
/// [submit] intentionally RETURNS the [AttendanceActionResult] and RETHROWS on
/// error: this refactor moves the repository call behind the UseCase and
/// centralises submit state, but the form keeps its exact success/navigation
/// and catch behaviour, so nothing the user sees changes.
class StaffTransferSubmitCubit extends Cubit<StaffTransferSubmitState> {
  StaffTransferSubmitCubit(
    this._submitStaffTransfer, {
    required GetStaffTransferFormListUseCase getStaffTransferFormListUseCase,
    required GetStaffProfileUseCase getStaffProfileUseCase,
    required StorageService storageService,
    required ApiClient apiClient,
  }) : _getStaffTransferFormListUseCase = getStaffTransferFormListUseCase,
       _getStaffProfileUseCase = getStaffProfileUseCase,
       _storage = storageService,
       _apiClient = apiClient,
       super(const StaffTransferSubmitInitial());

  final SubmitStaffTransferUseCase _submitStaffTransfer;
  final GetStaffTransferFormListUseCase _getStaffTransferFormListUseCase;
  final GetStaffProfileUseCase _getStaffProfileUseCase;
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

  /// Delegates to [GetStaffTransferFormListUseCase] — used by the View to
  /// resolve a selected staff member's current classroom from today's
  /// transfer-form list.
  Future<StaffAttendanceDailyPage> fetchTransferFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    return _getStaffTransferFormListUseCase(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      search: search,
      page: page,
      size: size,
    );
  }

  /// Delegates to [GetStaffProfileUseCase] — the View's last-resort fallback
  /// for a staff member's static default classroom.
  Future<StaffProfile> fetchStaffProfile({
    required String staffCode,
    bool forEditStaff = true,
  }) {
    return _getStaffProfileUseCase(
      staffCode: staffCode,
      forEditStaff: forEditStaff,
    );
  }

  /// True while a submit is in flight.
  bool get isSubmitting => state is StaffTransferSubmitInProgress;

  Future<AttendanceActionResult> submit({
    required StaffTransferRequest request,
  }) async {
    emit(const StaffTransferSubmitInProgress());
    try {
      _idempotencyKey ??= IdempotencyKey.generate();
      final result = await _submitStaffTransfer(
        request: request,
        idempotencyKey: _idempotencyKey,
      );
      if (!isClosed) emit(StaffTransferSubmitSuccess(result));
      _idempotencyKey = null;
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          StaffTransferSubmitFailure(ApiErrorHandler.extractErrorMessage(e)),
        );
      }
      rethrow;
    }
  }
}
