import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/routing/app_router.dart';
import 'package:wowcare/redesign/features/profile/presentation/pages/change_password_page.dart';
import 'package:wowcare/redesign/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:wowcare/redesign/features/profile/presentation/pages/notification_settings_page.dart';
import 'package:wowcare/redesign/features/profile/presentation/pages/profile_page.dart';

/// M13 My Profile routes.
///
/// Nested under the dashboard branch with **relative** paths (no leading
/// slash), so back returns to the dashboard and no tab lights up. They stay
/// relative even where they cover the tab bar: go_router concatenates a
/// child's path onto its parent's, so an absolute `/dashboard/profile/edit`
/// under `/dashboard/profile` would resolve to
/// `/dashboard/profile/dashboard/profile/edit`. What takes a screen over the
/// tab bar is `parentNavigatorKey: rootNavigatorKey`; the composed path is
/// still the one in `AppRoutes`.
///
/// The record itself stays inside the shell: it is a page you read, and the
/// five slots are still where you would want to go next. The three under it
/// each own the bottom of their own screen, so each covers the bar.
///
/// Absolute paths for navigation live in `AppRoutes`:
/// `/dashboard/profile`, `/dashboard/profile/edit`,
/// `/dashboard/profile/notification-settings` and
/// `/dashboard/profile/change-password`.
final List<RouteBase> profileRoutes = <RouteBase>[
  GoRoute(
    path: 'profile',
    builder: (context, state) => const ProfilePage(),
    routes: <RouteBase>[
      GoRoute(
        path: 'edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: 'notification-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: 'change-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChangePasswordPage(),
      ),
    ],
  ),
];
