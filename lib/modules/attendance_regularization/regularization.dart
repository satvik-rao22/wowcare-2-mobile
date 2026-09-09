import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'di/regularization_di.dart';
import 'presentation/entry/reg_dashboard_entry.dart';
import 'presentation/screens/reg_admin_inbox_screen.dart';
import 'presentation/screens/reg_staff_list_screen.dart';

/// **The module's only public surface.**
///
/// Nothing outside `lib/modules/attendance_regularization/` should import
/// anything else from this folder. If a second import appears, the facade is
/// missing something — extend it here rather than reaching inside.
///
/// The whole feature costs the host app **four lines**:
///
/// ```dart
/// // lib/app/di/di.dart          — beside registerAttendanceV2
/// registerRegularization(serviceLocator);
///
/// // lib/src/app_router.dart     — inside `routes: [...]`
/// ...Regularization.routes(),
///
/// // staff_dashboard.dart / admin_dashboard.dart
/// Regularization.dashboardEntry(),
/// ```
///
/// The **sign-in gate is not on that list on purpose.** It installs itself as
/// a Dio interceptor inside [register], so all 11 `StaffSignInForm` call sites
/// and kiosk v2 are covered without a single edit — and a sign-in path added
/// later inherits it automatically instead of silently bypassing it.
abstract final class Regularization {
  const Regularization._();

  static const String myRequestsRoute = '/regularization/my-requests';
  static const String adminInboxRoute = '/regularization/inbox';

  /// Registers the module and installs the sign-in gate. Call once at startup.
  static void register(GetIt sl) => registerRegularization(sl);

  /// Routes to spread into the app router's `routes` list.
  static List<RouteBase> routes() => <RouteBase>[
        GoRoute(
          path: myRequestsRoute,
          builder: (context, state) => RegStaffListScreen.connected(),
        ),
        GoRoute(
          path: adminInboxRoute,
          builder: (context, state) => RegAdminInboxScreen.connected(),
        ),
      ];

  /// The dashboard surface for both personas — the unresolved-day banner for
  /// staff, the approval card and count badge for admins.
  ///
  /// Renders nothing when there is nothing to show, so it can be placed
  /// unconditionally on either dashboard.
  static Widget dashboardEntry() => const RegDashboardEntry();

  /// The staff's own requests.
  static void openMyRequests(BuildContext context) =>
      GoRouter.of(context).push(myRequestsRoute);

  /// The admin approval list.
  static void openAdminInbox(BuildContext context) =>
      GoRouter.of(context).push(adminInboxRoute);

  /// Routes a notification tap. Returns false when the notification is not
  /// ours, so the host's resolver can carry on to its other cases.
  ///
  /// Staff go to their own list rather than straight into the sheet: arriving
  /// from a notification into a non-dismissible sheet is disorienting, and the
  /// list's banner offers the same action one tap away.
  static bool handleNotification(
    BuildContext context,
    String action, {
    Map<String, dynamic> data = const {},
  }) {
    switch (action.trim().toUpperCase()) {
      case 'STAFF_REGULARIZATION_APPROVED':
      case 'STAFF_REGULARIZATION_RAISED_SELF':
        openMyRequests(context);
        return true;
      case 'STAFF_REGULARIZATION_PENDING':
      case 'STAFF_REGULARIZATION_NEEDS_APPROVAL':
        openAdminInbox(context);
        return true;
      default:
        return false;
    }
  }
}
