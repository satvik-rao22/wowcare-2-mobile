import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/features/notifications/presentation/pages/notification_center_page.dart';

/// M12 Notifications routes.
///
/// Nested under the dashboard branch with a **relative** path (no leading
/// slash), so back returns to the dashboard and no tab lights up. go_router
/// concatenates a child's path onto its parent's, so an absolute
/// `/dashboard/notifications` here would resolve to
/// `/dashboard/dashboard/notifications`.
///
/// The center stays inside the shell. It is a list you read on the way to
/// somewhere else, and the five slots are still where you would want to go
/// next; nothing here owns the bottom of its own screen, so nothing needs to
/// cover the tab bar.
///
/// One screen, and its absolute path is already in `AppRoutes`:
/// `/dashboard/notifications`.
final List<RouteBase> notificationsRoutes = <RouteBase>[
  GoRoute(
    path: 'notifications',
    builder: (context, state) => const NotificationCenterPage(),
  ),
];
