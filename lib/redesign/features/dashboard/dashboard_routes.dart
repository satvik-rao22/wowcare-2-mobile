import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/placeholder_screen.dart';

/// M03 Dashboard and More routes.
///
/// [buildDashboardRoot] draws the branch root at its shell slot; [dashboardRoutes] are
/// nested under it with **relative** paths (no leading slash).
/// Absolute paths for navigation live in `AppRoutes`.

Widget buildDashboardRoot(BuildContext context, GoRouterState state) =>
    const PlaceholderScreen(title: 'M03 Dashboard and More');

final List<RouteBase> dashboardRoutes = <RouteBase>[];
