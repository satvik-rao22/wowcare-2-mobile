import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/placeholder_screen.dart';

/// M09 Communication routes.
///
/// [buildCommunicationRoot] draws the branch root at its shell slot; [communicationRoutes] are
/// nested under it with **relative** paths (no leading slash).
/// Absolute paths for navigation live in `AppRoutes`.

Widget buildCommunicationRoot(BuildContext context, GoRouterState state) =>
    const PlaceholderScreen(title: 'M09 Communication');

final List<RouteBase> communicationRoutes = <RouteBase>[];
