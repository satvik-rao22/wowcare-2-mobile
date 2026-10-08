import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'di/regularization_di.dart';
import 'domain/entities/regularization_request.dart';
import 'domain/usecases/get_requests_usecase.dart';
import 'presentation/entry/reg_gate_watcher.dart';
import 'presentation/entry/reg_requests_list.dart';
import 'presentation/screens/reg_admin_inbox_view.dart';
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

  /// Registers the module and installs the sign-in gate. Call once at startup.
  static void register(GetIt sl) => registerRegularization(sl);

  /// Routes to spread into the app router's `routes` list.
  static List<RouteBase> routes() => <RouteBase>[
    GoRoute(
      path: myRequestsRoute,
      builder: (context, state) => const RegMyRequestsScreen(),
    ),
  ];

  /// Invisible. Opens the gate sheet once per app session when the signed-in
  /// staff has an unresolved day — the sign-in gate covers the rest, so there
  /// is deliberately no card to go with it.
  static Widget gateWatcher() => const RegGateWatcher();

  /// One staff member's regularization requests, for embedding in the
  /// attendance profile. Scoped to [staffCode]; the actions each row offers
  /// come from the viewer's role and the request's own state.
  ///
  /// [from]/[to] narrow it to the attendance period the profile is showing, so
  /// the Requests chip follows the same month picker as the other chips.
  static Widget requestsList({
    required String staffCode,
    DateTime? from,
    DateTime? to,
  }) => RegRequestsList.connected(staffCode: staffCode, from: from, to: to);

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

  /// The admin approval list, for the Staff Attendance screen's **Request**
  /// tab. Brings no chrome — the tab supplies the app bar and title.
  ///
  /// There is deliberately no standalone route for it: one list, one place.
  /// The host decides how it is reached (the dashboard's attention card and
  /// the approval notification both open that tab).
  static Widget adminInbox() => RegAdminInboxView.connected();

  /// Routes a notification tap. Returns false when the notification is not
  /// ours, so the host's resolver can carry on to its other cases.
  ///
  /// Staff go to their own list rather than straight into the sheet: arriving
  /// from a notification into a non-dismissible sheet is disorienting, and an
  /// unresolved day is raised by the gate at the next sign-in anyway.
  ///
  /// [onAdminRequests] is called for the approver notifications, because their
  /// destination is the host's Staff Attendance **Request** tab. Passing it in
  /// keeps the module from having to know that screen or its tab order.
  static bool handleNotification(
    BuildContext context,
    String action, {
    required VoidCallback onAdminRequests,
    Map<String, dynamic> data = const {},
  }) {
    switch (action.trim().toUpperCase()) {
      case 'STAFF_REGULARIZATION_APPROVED':
      case 'STAFF_REGULARIZATION_RAISED_SELF':
        openMyRequests(context);
        return true;
      case 'STAFF_REGULARIZATION_PENDING':
      case 'STAFF_REGULARIZATION_NEEDS_APPROVAL':
        onAdminRequests();
        return true;
      default:
        return false;
    }
  }
}
