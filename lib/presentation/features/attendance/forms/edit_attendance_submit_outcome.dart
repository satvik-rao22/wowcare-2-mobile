/// Result of submitting an edit-attendance form (staff or student).
///
/// `success` carries the toast message. `failure` carries a ready-to-show
/// validation message. `error` carries the raw exception so the view can run
/// it through `ApiErrorHandler`. `noop` means a submit was already in flight.
class EditAttendanceSubmitOutcome {
  const EditAttendanceSubmitOutcome._({
    required this.success,
    this.message,
    this.error,
  });

  const EditAttendanceSubmitOutcome.success(String message)
    : this._(success: true, message: message);

  const EditAttendanceSubmitOutcome.failure(String message)
    : this._(success: false, message: message);

  const EditAttendanceSubmitOutcome.error(Object error)
    : this._(success: false, error: error);

  const EditAttendanceSubmitOutcome.noop() : this._(success: false);

  final bool success;

  /// Pre-formatted message for `success` and validation `failure` outcomes.
  final String? message;

  /// Raw exception for `error` outcomes; run through `ApiErrorHandler` to show.
  final Object? error;
}
