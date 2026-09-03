import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/pages/account_page.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/pages/more_page.dart';

/// M03 Dashboard and More.
///
/// The dashboard owns the first shell branch. More and Account are drill-downs
/// under it rather than slots of their own, so back returns to the dashboard
/// and no tab lights up while they are open.
Widget buildDashboardRoot(BuildContext context, GoRouterState state) =>
    const DashboardPage();

final List<RouteBase> dashboardRoutes = <RouteBase>[
  GoRoute(
    path: 'more',
    builder: (context, state) => const MorePage(),
    routes: <RouteBase>[
      GoRoute(
        path: 'account',
        builder: (context, state) => const AccountPage(),
      ),
    ],
  ),
];
