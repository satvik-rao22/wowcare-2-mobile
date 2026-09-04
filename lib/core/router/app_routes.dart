/// Centralized GoRouter path constants.
///
/// Seeded with the scheduling feature's paths as it migrates off raw
/// `Navigator.push`/`MaterialPageRoute` (see `app_router.dart`). Other
/// features keep their inline path strings until they migrate too — this
/// file is additive, not a full inventory of the app's 56 routes yet.
abstract final class AppRoutes {
  static const String scheduling = '/dashboard/scheduling';
  static const String staffScheduling = '/dashboard/staff-scheduling';

  /// Reachable from both [scheduling] and [staffScheduling] — siblings of
  /// both under the same `/dashboard` shell, not nested under either parent,
  /// since both entry screens push the same four destinations.
  static const String addShift = '/dashboard/add-shift-screen';
  static const String editShift = '/dashboard/edit-shift-screen';
  static const String viewShift = '/dashboard/view-shift-screen';
  static const String publishShifts = '/dashboard/publish-shifts-screen';
}
