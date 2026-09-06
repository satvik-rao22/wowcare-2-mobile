import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';

/// State for the student transfer submit flow (spinner + outcome).
sealed class StudentTransferSubmitState extends Equatable {
  const StudentTransferSubmitState();

  @override
  List<Object?> get props => [];
}

/// No submit attempted yet (or reset).
class StudentTransferSubmitInitial extends StudentTransferSubmitState {
  const StudentTransferSubmitInitial();
}

/// A submit request is in flight.
class StudentTransferSubmitInProgress extends StudentTransferSubmitState {
  const StudentTransferSubmitInProgress();
}

/// The backend responded. [result] carries the `success` flag + message; a
/// `success == false` result is still a normal (non-throwing) response.
class StudentTransferSubmitSuccess extends StudentTransferSubmitState {
  const StudentTransferSubmitSuccess(this.result);

  final AttendanceActionResult result;

  @override
  List<Object?> get props => [result];
}

/// The submit threw (network/parse/etc.). [message] is the user-facing message
/// extracted from the error.
class StudentTransferSubmitFailure extends StudentTransferSubmitState {
  const StudentTransferSubmitFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
