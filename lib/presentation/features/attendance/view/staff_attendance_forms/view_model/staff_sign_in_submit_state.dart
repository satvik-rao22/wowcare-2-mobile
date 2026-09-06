import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';

/// State for the staff sign-in submit flow (spinner + outcome).
sealed class StaffSignInSubmitState extends Equatable {
  const StaffSignInSubmitState();

  @override
  List<Object?> get props => [];
}

/// No submit attempted yet (or reset).
class StaffSignInSubmitInitial extends StaffSignInSubmitState {
  const StaffSignInSubmitInitial();
}

/// A submit request is in flight.
class StaffSignInSubmitInProgress extends StaffSignInSubmitState {
  const StaffSignInSubmitInProgress();
}

/// The backend responded. [result] carries the `success` flag + message; a
/// `success == false` result is still a normal (non-throwing) response.
class StaffSignInSubmitSuccess extends StaffSignInSubmitState {
  const StaffSignInSubmitSuccess(this.result);

  final AttendanceActionResult result;

  @override
  List<Object?> get props => [result];
}

/// The submit threw (network/parse/etc.). [message] is the user-facing message
/// extracted from the error.
class StaffSignInSubmitFailure extends StaffSignInSubmitState {
  const StaffSignInSubmitFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
