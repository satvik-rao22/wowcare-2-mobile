import 'package:flutter/foundation.dart';

/// Lightweight global signal fired after ANY attendance mutation (sign-in,
/// sign-out, transfer, override, etc.) for staff or students.
///
/// Kept-alive cards like [MyDayCard] and [MyChildsDayCard] listen to [tick]
/// and reload their attendance state so they always reflect the latest status
/// when returning to the dashboard.
class AttendanceEvents {
  AttendanceEvents._();

  /// Bumped once per successful attendance mutation.
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);

  /// Fire after an attendance action completes successfully.
  static void notifyChanged() => tick.value++;
}
