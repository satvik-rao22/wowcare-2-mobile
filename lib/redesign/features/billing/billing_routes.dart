import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/placeholder_screen.dart';

/// M10 Billing routes.
///
/// [buildBillingRoot] draws the branch root at its shell slot; [billingRoutes] are
/// nested under it with **relative** paths (no leading slash).
/// Absolute paths for navigation live in `AppRoutes`.

Widget buildBillingRoot(BuildContext context, GoRouterState state) =>
    const PlaceholderScreen(title: 'M10 Billing');

final List<RouteBase> billingRoutes = <RouteBase>[];
