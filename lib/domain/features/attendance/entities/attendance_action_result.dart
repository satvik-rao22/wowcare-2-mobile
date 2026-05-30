import 'package:equatable/equatable.dart';

/// Result of an attendance mutation (sign-in/out, transfer, mark-absent, edit).
///
/// Carries the backend `success` flag and human-readable `message` so the UI
/// can render the outcome without ever touching the network layer.
class AttendanceActionResult extends Equatable {
  const AttendanceActionResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  @override
  List<Object?> get props => [success, message];
}
