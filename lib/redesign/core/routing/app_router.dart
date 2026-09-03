import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/routing/dev_sign_in_screen.dart';
import 'package:wowcare/redesign/core/routing/shell_scaffold.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/features/activities/activities_routes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_routes.dart';
import 'package:wowcare/redesign/features/auth/auth_routes.dart';
import 'package:wowcare/redesign/features/billing/billing_routes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_routes.dart';
import 'package:wowcare/redesign/features/communication/communication_routes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_routes.dart';
import 'package:wowcare/redesign/features/events/events_routes.dart';
import 'package:wowcare/redesign/features/movements/movements_routes.dart';
import 'package:wowcare/redesign/features/newsletter/newsletter_routes.dart';
import 'package:wowcare/redesign/features/notifications/notifications_routes.dart';
import 'package:wowcare/redesign/features/profile/profile_routes.dart';
import 'package:wowcare/redesign/features/reports/reports_routes.dart';
import 'package:wowcare/redesign/features/scheduling/scheduling_routes.dart';
import 'package:wowcare/redesign/features/staff/staff_routes.dart';
import 'package:wowcare/redesign/features/students/students_routes.dart';

/// Forms, wizards and anything else that should cover the tab bar are pushed
/// here: `GoRoute(parentNavigatorKey: rootNavigatorKey, ...)`.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'redesign-root',
);

/// The branch order is the tab bar's slot order; the shell maps a persona's
/// five visible slots onto these six branches.
enum ShellBranch {
  dashboard,
  attendance,
  classrooms,
  activities,
  messages,
  billing,
}

/// One router, built once per app lifetime.
///
/// Cubits are provided in pages, never in a `pageBuilder`: a `..load()` there
/// refires on every navigation.
GoRouter buildAppRouter(SessionCubit session) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.signIn,
    refreshListenable: _StreamListenable(session.stream),
    redirect: (context, state) =>
        _redirect(session.state, state.matchedLocation),
    routes: <RouteBase>[
      // Until M01 lands, a preview sign-in stands in so the shell can be run.
      ...(authRoutes.isEmpty ? _devAuthRoutes : authRoutes),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          _branch(
            ShellBranch.dashboard,
            AppRoutes.dashboard,
            buildDashboardRoot,
            <RouteBase>[
              ...dashboardRoutes,
              ...notificationsRoutes,
              ...profileRoutes,
              ...studentsRoutes,
              ...staffRoutes,
              ...movementsRoutes,
              ...schedulingRoutes,
              ...newsletterRoutes,
              ...reportsRoutes,
              ...eventsRoutes,
            ],
          ),
          _branch(
            ShellBranch.attendance,
            AppRoutes.attendance,
            buildAttendanceRoot,
            attendanceRoutes,
          ),
          _branch(
            ShellBranch.classrooms,
            AppRoutes.classrooms,
            buildClassroomsRoot,
            classroomsRoutes,
          ),
          _branch(
            ShellBranch.activities,
            AppRoutes.activities,
            buildActivitiesRoot,
            activitiesRoutes,
          ),
          _branch(
            ShellBranch.messages,
            AppRoutes.messages,
            buildCommunicationRoot,
            communicationRoutes,
          ),
          _branch(
            ShellBranch.billing,
            AppRoutes.billing,
            buildBillingRoot,
            billingRoutes,
          ),
        ],
      ),
    ],
  );
}

final Map<ShellBranch, GlobalKey<NavigatorState>> _branchKeys =
    <ShellBranch, GlobalKey<NavigatorState>>{
      for (final b in ShellBranch.values)
        b: GlobalKey<NavigatorState>(debugLabel: 'redesign-${b.name}'),
    };

StatefulShellBranch _branch(
  ShellBranch branch,
  String root,
  GoRouterWidgetBuilder rootBuilder,
  List<RouteBase> children,
) {
  return StatefulShellBranch(
    navigatorKey: _branchKeys[branch],
    routes: <RouteBase>[
      GoRoute(
        path: root,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: ValueKey<String>(root),
          child: rootBuilder(context, state),
        ),
        routes: children,
      ),
    ],
  );
}

/// The auth gate and the kiosk lockdown.
String? _redirect(SessionState session, String location) {
  final onAuth = _authPaths.any(
    (p) => location == p || location.startsWith('$p/'),
  );
  final onKiosk =
      location == AppRoutes.kiosk || location.startsWith('${AppRoutes.kiosk}/');

  switch (session.status) {
    case SessionStatus.signedOut:
      return onAuth ? null : AppRoutes.signIn;
    case SessionStatus.kiosk:
      // Locked to the door screen until an admin leaves kiosk mode.
      return onKiosk ? null : AppRoutes.kiosk;
    case SessionStatus.signedIn:
      if (onAuth) return AppRoutes.dashboard;
      return null;
  }
}

final List<RouteBase> _devAuthRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.signIn,
    builder: (context, state) => const DevSignInScreen(),
  ),
];

const List<String> _authPaths = <String>[
  AppRoutes.signIn,
  AppRoutes.forgotPassword,
  AppRoutes.resetPassword,
];

/// Lets [GoRouter.refreshListenable] follow a cubit stream.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
