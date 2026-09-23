import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'di/regularization_di.dart';
import 'domain/entities/regularization_request.dart';
import 'domain/usecases/get_requests_usecase.dart';
import 'presentation/entry/reg_gate_watcher.dart';
import 'presentation/entry/reg_requests_list.dart';
import 'presentation/screens/reg_admin_inbox_screen.dart';
import 'presentation/screens/reg_my_requests_screen.dart';

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
          builder: (context, state) => const RegMyRequestsScreen(),
        ),
        GoRoute(
          path: adminInboxRoute,
          builder: (context, state) => RegAdminInboxScreen.connected(),
        ),
      ];

  /// Invisible. Opens the gate sheet once per app session when the signed-in
  /// staff has an unresolved day — the sign-in gate covers the rest, so there
  /// is deliberately no card to go with it.
  static Widget gateWatcher() => const RegGateWatcher();

  /// One staff member's regularization requests, for embedding in the
  /// attendance profile. Scoped to [staffCode]; the actions each row offers
  /// come from the viewer's role and the request's own state.
  static Widget requestsList({required String staffCode}) =>
      RegRequestsList.connected(staffCode: staffCode);

  /// Requests awaiting this admin's approval, for the dashboard's attention
  /// grid. Returns 0 rather than throwing — a count must never break a
  /// dashboard.
  static Future<int> pendingApprovalCount(GetIt sl) async {
    try {
      final page = await sl<GetRequestsUseCase>()(
        status: RegStatus.pending,
        page: 0,
        size: 1,
      );
      return page.total;
    } catch (_) {
      return 0;
    }
  }

  /// The staff's own requests.
  static Future<void> openMyRequests(BuildContext context) =>
      GoRouter.of(context).push(myRequestsRoute);

  /// The admin approval list.
  /// Completes when the inbox is popped, so callers can refresh a count that
  /// approving may have changed.
  static Future<void> openAdminInbox(BuildContext context) =>
      GoRouter.of(context).push(adminInboxRoute);

  /// Routes a notification tap. Returns false when the notification is not
  /// ours, so the host's resolver can carry on to its other cases.
  ///
  /// Staff go to their own list rather than straight into the sheet: arriving
  /// from a notification into a non-dismissible sheet is disorienting, and an
  /// unresolved day is raised by the gate at the next sign-in anyway.
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
