import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
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
  StudentSignOutSubmitCubit(this._submitStudentSignOut)
    : super(const StudentSignOutSubmitInitial());

  final SubmitStudentSignOutUseCase _submitStudentSignOut;

  String? _idempotencyKey;

  /// True while a submit is in flight.
  bool get isSubmitting => state is StudentSignOutSubmitInProgress;

  Future<AttendanceActionResult> submit({
    required StudentSignOutRequest request,
    required bool isParent,
  }) async {
    emit(const StudentSignOutSubmitInProgress());
    try {
      _idempotencyKey ??= IdempotencyKey.generate();
      final result = await _submitStudentSignOut(
        request: request,
        isParent: isParent,
        idempotencyKey: _idempotencyKey,
      );
      if (!isClosed) emit(StudentSignOutSubmitSuccess(result));
      _idempotencyKey = null;
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          StudentSignOutSubmitFailure(ApiErrorHandler.extractErrorMessage(e)),
        );
      }
      rethrow;
    }
  }
}
