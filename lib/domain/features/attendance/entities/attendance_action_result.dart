import 'package:equatable/equatable.dart';

/// Result of an attendance mutation (sign-in/out, transfer, mark-absent, edit).
///
/// Carries the backend `success` flag and human-readable `message` so the UI
/// can render the outcome without ever touching the network layer.
class AttendanceActionResult extends Equatable {
  const AttendanceActionResult({
    required this.success,
    required this.message,
    this.currentClassroomCode,
    this.primaryClassroomCode,
  });

  final bool success;
  final String message;

  /// Present on transfer responses — the staff/student's classroom
  /// immediately after this mutation, straight from the backend (so callers
  /// never need to infer it from the request payload).
  final String? currentClassroomCode;

  /// Present on some transfer/profile-mutation responses as an alternate
  /// name for the same "current classroom" concept.
  final String? primaryClassroomCode;

  @override
  List<Object?> get props => [
    success,
    message,
    currentClassroomCode,
    primaryClassroomCode,
  ];
}
