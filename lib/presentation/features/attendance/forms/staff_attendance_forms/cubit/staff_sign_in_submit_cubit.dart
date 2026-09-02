import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_in_request.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_sign_in_usecase.dart';

import 'staff_sign_in_submit_state.dart';

/// Owns the staff sign-in submit call and its in-progress/success/failure
/// state, routing the mutation through [SubmitStaffSignInUseCase] instead of
/// the View touching [AttendanceRepository] directly.
///
/// [submit] intentionally RETURNS the [AttendanceActionResult] and RETHROWS on
/// error: this refactor moves the repository call behind the UseCase and
/// centralises submit state, but the form keeps its exact success/navigation
/// and catch behaviour, so nothing the user sees changes.
class StaffSignInSubmitCubit extends Cubit<StaffSignInSubmitState> {
  StaffSignInSubmitCubit(this._submitStaffSignIn)
    : super(const StaffSignInSubmitInitial());

  final SubmitStaffSignInUseCase _submitStaffSignIn;

  String? _idempotencyKey;

  /// True while a submit is in flight.
  bool get isSubmitting => state is StaffSignInSubmitInProgress;

  Future<AttendanceActionResult> submit({
    required StaffSignInRequest request,
    required bool isSelf,
  }) async {
    emit(const StaffSignInSubmitInProgress());
    try {
      _idempotencyKey ??= IdempotencyKey.generate();
      final result = await _submitStaffSignIn(
        request: request,
        isSelf: isSelf,
        idempotencyKey: _idempotencyKey,
      );
      if (!isClosed) emit(StaffSignInSubmitSuccess(result));
      _idempotencyKey = null;
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          StaffSignInSubmitFailure(ApiErrorHandler.extractErrorMessage(e)),
        );
      }
      rethrow;
    }
  }
}
