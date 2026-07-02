/// Shared result type for the activity create/edit form cubits
/// (medication, bottle, nap, …). Each submit/approve/reject method returns one
/// of these and the view maps it onto a snackbar + navigation:
///
///  * `successExit` → success toast + `CoreUtils.exitActivityFlow`
///  * `successPop`  → success toast + `Navigator.pop(true)`
///  * `warning`     → warning toast only
///  * `error`       → error toast only
///  * `noop`        → nothing (e.g. a dialog already handled it, or a guard hit)
enum ActivityFormResultType { warning, error, successExit, successPop, noop }

class ActivityFormOutcome {
  const ActivityFormOutcome._(this.type, [this.message = '']);

  const ActivityFormOutcome.warning(String message)
      : this._(ActivityFormResultType.warning, message);
  const ActivityFormOutcome.error(String message)
      : this._(ActivityFormResultType.error, message);
  const ActivityFormOutcome.successExit(String message)
      : this._(ActivityFormResultType.successExit, message);
  const ActivityFormOutcome.successPop(String message)
      : this._(ActivityFormResultType.successPop, message);
  const ActivityFormOutcome.noop() : this._(ActivityFormResultType.noop);

  final ActivityFormResultType type;
  final String message;
}
