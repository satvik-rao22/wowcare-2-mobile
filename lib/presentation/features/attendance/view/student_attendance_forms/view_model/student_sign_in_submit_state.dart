import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';

/// State for the student sign-in submit flow (spinner + outcome).
sealed class StudentSignInSubmitState extends Equatable {
  const StudentSignInSubmitState();

  @override
  List<Object?> get props => [];
}

/// No submit attempted yet (or reset).
class StudentSignInSubmitInitial extends StudentSignInSubmitState {
  const StudentSignInSubmitInitial();
}

/// A submit request is in flight.
class StudentSignInSubmitInProgress extends StudentSignInSubmitState {
  const StudentSignInSubmitInProgress();
}

/// The backend responded. [result] carries the `success` flag + message; a
/// `success == false` result is still a normal (non-throwing) response.
class StudentSignInSubmitSuccess extends StudentSignInSubmitState {
  const StudentSignInSubmitSuccess(this.result);

  final AttendanceActionResult result;

  @override
  List<Object?> get props => [result];
}

/// The submit threw (network/parse/etc.). [message] is the user-facing message
/// extracted from the error.
class StudentSignInSubmitFailure extends StudentSignInSubmitState {
  const StudentSignInSubmitFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
