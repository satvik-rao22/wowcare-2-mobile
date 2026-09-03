import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/placeholder_screen.dart';

/// M08 Activities routes.
///
/// [buildActivitiesRoot] draws the branch root at its shell slot; [activitiesRoutes] are
/// nested under it with **relative** paths (no leading slash).
/// Absolute paths for navigation live in `AppRoutes`.

Widget buildActivitiesRoot(BuildContext context, GoRouterState state) =>
    const PlaceholderScreen(title: 'M08 Activities');

final List<RouteBase> activitiesRoutes = <RouteBase>[];
