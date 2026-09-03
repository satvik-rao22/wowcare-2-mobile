import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/placeholder_screen.dart';

/// M07 Classrooms routes.
///
/// [buildClassroomsRoot] draws the branch root at its shell slot; [classroomsRoutes] are
/// nested under it with **relative** paths (no leading slash).
/// Absolute paths for navigation live in `AppRoutes`.

Widget buildClassroomsRoot(BuildContext context, GoRouterState state) =>
    const PlaceholderScreen(title: 'M07 Classrooms');

final List<RouteBase> classroomsRoutes = <RouteBase>[];
