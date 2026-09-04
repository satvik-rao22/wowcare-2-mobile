import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/app_router.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/add_staff_page.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/edit_staff_page.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/staff_page.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/staff_profile_page.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/staff_schedule_page.dart';

/// M06 Staff routes.
///
/// Staff is reached from More, so these nest under the **dashboard** branch:
/// back returns to the dashboard and no tab lights up, which is the app's own
/// `_syncSelectedItemFromRoute` rule.
///
/// Paths are **relative**, including the ones that cover the tab bar:
/// go_router concatenates a child's path onto its parent's, so an absolute
/// `/dashboard/staff/new` declared under `/dashboard` would resolve to
/// `/dashboard/dashboard/staff/new`. What lifts a screen over the tab bar is
/// `parentNavigatorKey: rootNavigatorKey`, which pushes it on the root
/// navigator; the composed path is still the one in `AppRoutes`.
///
/// `new` is declared before `:id` because go_router matches in order, and
/// `/dashboard/staff/new` would otherwise open a staff member coded "new".
///
/// Absolute paths for navigation live in `AppRoutes`: `/dashboard/staff`,
/// `/dashboard/staff/new`, `/dashboard/staff/:id`, `/dashboard/staff/:id/edit`
/// and `/dashboard/staff/:id/schedule`.
final List<RouteBase> staffRoutes = <RouteBase>[
  GoRoute(
    path: 'staff',
    builder: (context, state) => const StaffPage(),
    routes: <RouteBase>[
      GoRoute(
        path: 'new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddStaffPage(),
      ),
      GoRoute(
        path: ':id',
        builder: (context, state) =>
            StaffProfilePage(staffId: state.pathParameters['id']!),
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) =>
                EditStaffPage(staffId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'schedule',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) =>
                StaffSchedulePage(staffId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  ),
];
