import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/placeholder_screen.dart';

/// M04 Attendance routes.
///
/// [buildAttendanceRoot] draws the branch root at its shell slot; [attendanceRoutes] are
/// nested under it with **relative** paths (no leading slash).
/// Absolute paths for navigation live in `AppRoutes`.

Widget buildAttendanceRoot(BuildContext context, GoRouterState state) =>
    const PlaceholderScreen(title: 'M04 Attendance');

final List<RouteBase> attendanceRoutes = <RouteBase>[];
