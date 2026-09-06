import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';

/// State for the staff sign-out submit flow (spinner + outcome).
sealed class StaffSignOutSubmitState extends Equatable {
  const StaffSignOutSubmitState();

  @override
  List<Object?> get props => [];
}

/// No submit attempted yet (or reset).
class StaffSignOutSubmitInitial extends StaffSignOutSubmitState {
  const StaffSignOutSubmitInitial();
}

/// A submit request is in flight.
class StaffSignOutSubmitInProgress extends StaffSignOutSubmitState {
  const StaffSignOutSubmitInProgress();
}

/// The backend responded. [result] carries the `success` flag + message; a
/// `success == false` result is still a normal (non-throwing) response.
class StaffSignOutSubmitSuccess extends StaffSignOutSubmitState {
  const StaffSignOutSubmitSuccess(this.result);

  final AttendanceActionResult result;

  @override
  List<Object?> get props => [result];
}

/// The submit threw (network/parse/etc.). [message] is the user-facing message
/// extracted from the error.
class StaffSignOutSubmitFailure extends StaffSignOutSubmitState {
  const StaffSignOutSubmitFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
