import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_sign_in_usecase.dart';

import 'student_sign_in_submit_state.dart';

/// Owns the student sign-in submit call and its in-progress/success/failure
/// state, routing the mutation through [SubmitStudentSignInUseCase] instead of
/// the View touching [AttendanceRepository] directly.
///
/// [submit] intentionally RETURNS the [AttendanceActionResult] and RETHROWS on
/// error: this refactor moves the repository call behind the UseCase and
/// centralises submit state, but the form keeps its exact success/navigation
/// and catch behaviour, so nothing the user sees changes.
class StudentSignInSubmitCubit extends Cubit<StudentSignInSubmitState> {
  StudentSignInSubmitCubit(this._submitStudentSignIn)
    : super(const StudentSignInSubmitInitial());

  final SubmitStudentSignInUseCase _submitStudentSignIn;

  /// True while a submit is in flight.
  bool get isSubmitting => state is StudentSignInSubmitInProgress;

  Future<AttendanceActionResult> submit({
    required Map<String, dynamic> payload,
    required bool isParent,
  }) async {
    emit(const StudentSignInSubmitInProgress());
    try {
      final result = await _submitStudentSignIn(
        payload: payload,
        isParent: isParent,
      );
      if (!isClosed) emit(StudentSignInSubmitSuccess(result));
      return result;
    } catch (e) {
      if (!isClosed) {
        emit(
          StudentSignInSubmitFailure(ApiErrorHandler.extractErrorMessage(e)),
        );
      }
      rethrow;
    }
  }
}
