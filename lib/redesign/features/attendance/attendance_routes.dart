import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/routing/app_router.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/pages/attendance_page.dart';
import 'package:wowcare/redesign/features/attendance/presentation/pages/attendance_range_page.dart';
import 'package:wowcare/redesign/features/attendance/presentation/pages/sign_attendance_page.dart';

/// M04 Attendance routes.
///
/// [buildAttendanceRoot] draws the branch root at its shell slot;
/// [attendanceRoutes] are nested under it with **relative** paths. They stay
/// relative even where they cover the tab bar: go_router concatenates a
/// child's path onto its parent's, so an absolute `/attendance/sign-in` under
/// `/attendance` would resolve to `/attendance/attendance/sign-in`. What
/// lifts a screen over the tab bar is `parentNavigatorKey: rootNavigatorKey`;
/// the composed path is still the one in `AppRoutes`.
///
/// `sign-in`, `sign-out` and `range` are all literal segments, so none of
/// them can be read as a record code. Nothing here takes a path parameter:
/// the two forms are about a set of people, which travels as typed `extra`.
///
/// Absolute paths for navigation live in `AppRoutes`: `/attendance`,
/// `/attendance/sign-in`, `/attendance/sign-out` and `/attendance/range`.
Widget buildAttendanceRoot(BuildContext context, GoRouterState state) =>
    const AttendancePage();

final List<RouteBase> attendanceRoutes = <RouteBase>[
  // The two forms own the bottom of their own screen, so they cover the tab
  // bar rather than sitting inside it.
  GoRoute(
    path: 'sign-in',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => SignAttendancePage(
      args: state.extra as SignAttendanceArgs? ?? _emptySignIn,
    ),
  ),
  GoRoute(
    path: 'sign-out',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => SignAttendancePage(
      args: state.extra as SignAttendanceArgs? ?? _emptySignOut,
    ),
  ),
  // The range view is still a list, so the five slots stay reachable under
  // it and it keeps the tab bar.
  GoRoute(
    path: 'range',
    builder: (context, state) => AttendanceRangePage(
      range: state.extra as DateRange? ?? _defaultRange,
      today: _today,
    ),
  ),
];

/// The school's own day, which is what "today" means everywhere in M04.
/// Phase 5 swaps this for `SchoolZoneDateTime` and no screen changes.
DateTime get _today => DemoData.today;

/// A deep link arrives with nothing picked, and the form says so rather than
/// crashing on an empty list.
const SignAttendanceArgs _emptySignIn = SignAttendanceArgs(
  kind: SignKind.signIn,
  audience: AttendanceAudience.students,
);

const SignAttendanceArgs _emptySignOut = SignAttendanceArgs(
  kind: SignKind.signOut,
  audience: AttendanceAudience.students,
);

/// This month to date, which is the range 4f opens on.
DateRange get _defaultRange =>
    DateRange(from: DateTime(_today.year, _today.month), to: _today);
