/// Outcome of `ActivityEditorCubit.validateStudentsWithinAttendanceWindow` —
/// pure data, no `BuildContext`/UI. The calling screen shows [failureMessage]
/// via its own snackbar when [isValid] is false.
class AttendanceWindowValidationResult {
  const AttendanceWindowValidationResult.valid()
    : isValid = true,
      failureMessage = null;

  const AttendanceWindowValidationResult.invalid(this.failureMessage)
    : isValid = false;

  final bool isValid;
  final String? failureMessage;
}
