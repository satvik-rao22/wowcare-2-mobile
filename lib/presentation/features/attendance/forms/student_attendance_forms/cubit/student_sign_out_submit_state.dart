import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';

/// State for the student sign-out submit flow (spinner + outcome).
sealed class StudentSignOutSubmitState extends Equatable {
  const StudentSignOutSubmitState();

  @override
  List<Object?> get props => [];
}

/// No submit attempted yet (or reset).
class StudentSignOutSubmitInitial extends StudentSignOutSubmitState {
  const StudentSignOutSubmitInitial();
}

/// A submit request is in flight.
class StudentSignOutSubmitInProgress extends StudentSignOutSubmitState {
  const StudentSignOutSubmitInProgress();
}

/// The backend responded. [result] carries the `success` flag + message; a
/// `success == false` result is still a normal (non-throwing) response.
class StudentSignOutSubmitSuccess extends StudentSignOutSubmitState {
  const StudentSignOutSubmitSuccess(this.result);

  final AttendanceActionResult result;

  @override
  List<Object?> get props => [result];
}

/// The submit threw (network/parse/etc.). [message] is the user-facing message
/// extracted from the error.
class StudentSignOutSubmitFailure extends StudentSignOutSubmitState {
  const StudentSignOutSubmitFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
