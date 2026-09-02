import 'package:equatable/equatable.dart';

/// Shared state for attendance-record delete flows (staff and student).
///
/// Deletes carry no result payload, so the states hold only progress/outcome.
sealed class AttendanceDeleteState extends Equatable {
  const AttendanceDeleteState();

  @override
  List<Object?> get props => [];
}

/// No delete attempted yet (or reset).
class AttendanceDeleteInitial extends AttendanceDeleteState {
  const AttendanceDeleteInitial();
}

/// A delete request is in flight.
class AttendanceDeleteInProgress extends AttendanceDeleteState {
  const AttendanceDeleteInProgress();
}

/// The delete completed successfully.
class AttendanceDeleteSuccess extends AttendanceDeleteState {
  const AttendanceDeleteSuccess();
}

/// The delete threw. [message] is the user-facing message extracted from the
/// error.
class AttendanceDeleteFailure extends AttendanceDeleteState {
  const AttendanceDeleteFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
