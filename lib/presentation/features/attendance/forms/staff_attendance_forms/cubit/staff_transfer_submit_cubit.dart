import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_transfer_request.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_transfer_usecase.dart';

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
  StaffTransferSubmitCubit(this._submitStaffTransfer)
    : super(const StaffTransferSubmitInitial());

  final SubmitStaffTransferUseCase _submitStaffTransfer;

  String? _idempotencyKey;

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
