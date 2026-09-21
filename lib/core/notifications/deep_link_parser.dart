import '../../data/features/notifications/models/push_notification_model.dart';
import '../../domain/features/notifications/entities/notification_action.dart';
import '../../domain/features/notifications/entities/push_notification.dart';

/// Turns an incoming Universal Link / Android App Link (e.g. tapped from an
/// email button) into the same [PushNotification] shape FCM produces, so it
/// can be routed through the exact same [NotificationRouteResolver] table and
/// [PushNotificationCubit] navigation pipeline as a real push tap — one
/// action→destination table, one set of school-switch/persona rules, for
/// both entry points.
///
/// Returns null when the link carries no `action` and its path doesn't match
/// a known action-less link family either — nothing in the resolver table to
/// route to (e.g. an unrelated/marketing path also under this host).
PushNotification? pushNotificationFromDeepLinkUri(Uri uri) {
  final explicitAction = uri.queryParameters['action']?.trim();
  final action = (explicitAction != null && explicitAction.isNotEmpty)
      ? explicitAction
      : _inferActionFromPath(uri);
  if (action == null || action.isEmpty) return null;

  final data = <String, String>{...uri.queryParameters};
  // Some link families (e.g. the web app's own daily-activities share link)
  // use their own key names instead of the ones NotificationRouteResolver
  // reads — normalize the ones we know about rather than teaching the
  // resolver every link family's vocabulary. Never overwrites a key the
  // link already set directly.
  final targetCode = uri.queryParameters['targetCode']?.trim();
  if ((targetCode ?? '').isNotEmpty && !data.containsKey('studentCode')) {
    data['studentCode'] = targetCode!;
  }
  final recordCode = uri.queryParameters['recordCode']?.trim();
  if ((recordCode ?? '').isNotEmpty && !data.containsKey('activityCode')) {
    data['activityCode'] = recordCode!;
  }

  return PushNotificationModel(
    title: null,
    body: null,
    action: action,
    type: uri.queryParameters['type'],
    data: {
      ...data,
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

/// Some link families carry no `action` query param at all — the action is
/// implied by the path instead. Add a case here whenever a new such family
/// shows up; every other link family must keep sending `action` explicitly.
String? _inferActionFromPath(Uri uri) {
  final segments = uri.pathSegments.map((s) => s.toLowerCase()).toSet();
  if (segments.contains('daily-activities')) {
    return NotificationAction.activityRecorded;
  }
  return null;
}
