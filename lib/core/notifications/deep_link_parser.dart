import '../../data/features/notifications/models/push_notification_model.dart';
import '../../domain/features/notifications/entities/push_notification.dart';

/// Turns an incoming Universal Link / Android App Link (e.g. tapped from an
/// email button) into the same [PushNotification] shape FCM produces, so it
/// can be routed through the exact same [NotificationRouteResolver] table and
/// [PushNotificationCubit] navigation pipeline as a real push tap — one
/// action→destination table, one set of school-switch/persona rules, for
/// both entry points.
///
/// Returns null when the link carries no `action` — nothing in the resolver
/// table to route to (e.g. an unrelated/marketing path also under this host).
PushNotification? pushNotificationFromDeepLinkUri(Uri uri) {
  final action = uri.queryParameters['action']?.trim();
  if (action == null || action.isEmpty) return null;

  return PushNotificationModel(
    title: null,
    body: null,
    action: action,
    type: uri.queryParameters['type'],
    data: {
      ...uri.queryParameters,
      // NotificationRouteResolver._codeFromEmbeddedLink resolves a student
      // code by scanning every data VALUE for a URL that itself carries a
      // `targetCode` param — the shape the backend already embeds in push
      // payloads (e.g. `physicalExaminationDetailsLink`). This link's own
      // query params are already flat (targetCode, schoolCode, ... as plain
      // keys), so stashing the full URL under this key satisfies that same
      // scan and keeps this link resolving through the identical codepath a
      // push tap would, instead of duplicating per-action key mapping here.
      '__deepLink': uri.toString(),
    },
  );
}
