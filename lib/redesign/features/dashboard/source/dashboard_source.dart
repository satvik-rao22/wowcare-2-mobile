import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// Where M03 gets its data. Fixtures during the UI phase; in the last phase
/// one implementation fans out across the calls the three dashboards already
/// make: the attention counts, today's staff attendance row, the school
/// status summary, ratio and shift monitoring, the billing range summary, and
/// a guardian's own students.
///
/// Nothing here is new API work. Every field traces to a response the app
/// already receives and simply does not draw.
abstract interface class DashboardSource {
  /// Everything the dashboard for [persona] draws, in one call.
  Future<DashboardSnapshot> load(Persona persona);

  /// The signed-in staff member's own Sign Out (3A3, 3S3). [at] carries the
  /// corrected time an Admin may set; Staff pass null and get the clock.
  Future<MyDay> signOutSelf({required MyDay day, DateTime? at});

  /// Move to another classroom for the rest of the shift.
  Future<MyDay> transfer({required MyDay day, required String classroomName});

  /// Mark, or unmark, the signed-in staff member absent for today.
  Future<MyDay> setAbsent({required MyDay day, required bool isAbsent});

  /// A guardian signing their own student out from the dashboard (3P3).
  Future<ChildDay> signOutChild(ChildDay child);

  /// Tell me before the school day ends.
  Future<ChildDay> setReminder({required ChildDay child, required bool isOn});
}
