import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';

/// State for the staff transfer submit flow (spinner + outcome).
sealed class StaffTransferSubmitState extends Equatable {
  const StaffTransferSubmitState();

  @override
  List<Object?> get props => [];
}

/// No submit attempted yet (or reset).
class StaffTransferSubmitInitial extends StaffTransferSubmitState {
  const StaffTransferSubmitInitial();
}

/// A submit request is in flight.
class StaffTransferSubmitInProgress extends StaffTransferSubmitState {
  const StaffTransferSubmitInProgress();
}

/// The backend responded. [result] carries the `success` flag + message; a
/// `success == false` result is still a normal (non-throwing) response.
class StaffTransferSubmitSuccess extends StaffTransferSubmitState {
  const StaffTransferSubmitSuccess(this.result);

  final AttendanceActionResult result;

  @override
  List<Object?> get props => [result];
}

/// The submit threw (network/parse/etc.). [message] is the user-facing message
/// extracted from the error.
class StaffTransferSubmitFailure extends StaffTransferSubmitState {
  const StaffTransferSubmitFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
