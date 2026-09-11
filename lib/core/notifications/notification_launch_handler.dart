import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/notifications/deep_link_parser.dart';
import 'package:wowcare/core/notifications/native_notification_bridge.dart';
import 'package:wowcare/core/platform/ios_geofence_tap_bridge.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/login_persona_util.dart';
import 'package:wowcare/core/utils/notification_payload.dart';
import 'package:wowcare/data/features/notifications/models/push_notification_model.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';
import 'package:wowcare/src/app_router.dart';

/// The launching user's persona, read straight from storage.
///
/// [NotificationRouteResolver.resolve] routes billing and newsletter
/// notifications per persona, but at bootstrap there is no widget tree yet — so
/// `RoleCubit` (which the warm-start tap path in `PushNotificationCubit` reads)
/// doesn't exist. Without this, a cold-start tap defaulted to `isGuardian:
/// false` and sent a parent to the staff destination — e.g. a newsletter tap
/// landing on the messaging branch (room chat for parents) instead of their
/// newsletter screen.
///
/// Shares `RoleCubit`'s rule via [resolvePersonaFamilyFromStorage], so a
/// cold-start tap resolves to the same place a warm one does. Falls back to
/// `admin` (the default `RoleState` carries) if storage can't be read.
///
/// Safe to call here: `AppBootstrap.initialize` runs `configureDependencies()`
/// well before this, so the service locator is ready.
Future<String> _launchPersonaFamily() async {
  try {
    return await resolvePersonaFamilyFromStorage(
      serviceLocator<StorageService>(),
    );
  } catch (_) {
    return 'admin';
  }
}

/// Killed-state launch: if a notification tap cold-started the app, capture
/// and resolve it to a deep-link NOW — before any UI builds — so the splash
/// routes there instead of the dashboard. Doing this in bootstrap (rather than
/// in the cubit's post-frame init) removes any race with the splash's auth
/// timer.
Future<void> resolvePendingLaunchNotification() async {
  try {
    final persona = await _launchPersonaFamily();
    final isGuardian = persona == 'parent';
    final isAdminPersona = persona == 'admin';

    final launchMessage = await FirebaseMessaging.instance.getInitialMessage();
    AppLogger.d(
      '[main] getInitialMessage → ${launchMessage == null ? "null" : launchMessage.data}',
    );
    Map<String, String>? launchData;
    if (launchMessage != null) {
      launchData = launchMessage.data.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      );
    } else {
      // getInitialMessage() returns null here (manual plugin registration in
      // MainActivity doesn't feed the launch intent to the Firebase plugin), so
      // read the killed-state tap's `data` payload natively from the intent.
      launchData = await readNativeLaunchNotification();
      AppLogger.d('[main] native launch data → $launchData');
    }
    if (launchData != null && (launchData['action'] ?? '').isNotEmpty) {
      final dest = NotificationRouteResolver.resolve(
        PushNotificationModel(
          title: null,
          body: null,
          action: launchData['action'],
          type: launchData['type'],
          data: launchData,
        ),
        isGuardian: isGuardian,
        isAdminPersona: isAdminPersona,
      );
      if (dest != null) pendingNotificationDeepLink = dest.location;
      AppLogger.d(
        '[main] stashed pendingNotificationDeepLink=$pendingNotificationDeepLink',
      );
      // Capture the target org/school so the splash can switch the active school
      // (multi-school user) before performing this deep-link redirect.
      final launchOrg =
          (launchData['organizationCode'] ??
                  launchData['orgCode'] ??
                  launchData['organization_code'] ??
                  '')
              .trim();
      final launchSchool =
          (launchData['schoolCode'] ?? launchData['school_code'] ?? '').trim();
      if (launchOrg.isNotEmpty && launchSchool.isNotEmpty) {
        pendingNotificationOrgSchool = {
          'organizationCode': launchOrg,
          'schoolCode': launchSchool,
        };
        AppLogger.d(
          '[main] stashed pendingNotificationOrgSchool=$pendingNotificationOrgSchool',
        );
      }
    }

    // Killed-state tap of a LOCAL notification: when an FCM message arrives
    // while the app is in the FOREGROUND, the OS shows no tray notification —
    // our app shows a local one (geofence service) whose payload IS the resolved
    // deep-link. If the user later kills the app and taps that local
    // notification, this is the only way to recover it (getInitialMessage and
    // the FCM intent extras are both empty for a local-notification launch).
    if (pendingNotificationDeepLink == null) {
      final launchDetails = await FlutterLocalNotificationsPlugin()
          .getNotificationAppLaunchDetails();
      final payload = launchDetails?.notificationResponse?.payload?.trim();
      AppLogger.d(
        '[main] localNotif launch: didLaunch=${launchDetails?.didNotificationLaunchApp} payload="$payload"',
      );
      if (launchDetails?.didNotificationLaunchApp == true &&
          payload != null &&
          payload.isNotEmpty) {
        // Payload may carry the target org/school (foreground-shown local notif);
        // split it out so the splash can switch school before redirecting.
        final decoded = decodeNotificationPayload(payload);
        pendingNotificationDeepLink = decoded.location;
        if ((decoded.organizationCode ?? '').isNotEmpty &&
            (decoded.schoolCode ?? '').isNotEmpty) {
          pendingNotificationOrgSchool = {
            'organizationCode': decoded.organizationCode!,
            'schoolCode': decoded.schoolCode!,
          };
        }
        AppLogger.d(
          '[main] stashed (local notif) pendingNotificationDeepLink=$pendingNotificationDeepLink '
          'orgSchool=$pendingNotificationOrgSchool',
        );
      }
    }

    // iOS: native geofence UNNotification tap (not shown via flutter_local_notifications,
    // so getNotificationAppLaunchDetails() misses it). AppDelegate stores the action
    // in UserDefaults; we read it here and resolve to /dashboard.
    if (pendingNotificationDeepLink == null) {
      final geofenceTapData = await readIosGeofenceTap();
      if (geofenceTapData != null &&
          (geofenceTapData['action'] ?? '').isNotEmpty) {
        final dest = NotificationRouteResolver.resolve(
          PushNotificationModel(
            title: null,
            body: null,
            action: geofenceTapData['action'],
            type: null,
            data: geofenceTapData,
          ),
          isGuardian: isGuardian,
          isAdminPersona: isAdminPersona,
        );
        if (dest != null) pendingNotificationDeepLink = dest.location;
        AppLogger.d(
          '[main] stashed (iOS geofence tap) pendingNotificationDeepLink=$pendingNotificationDeepLink',
        );
      }
    }

    // Killed-state launch via a Universal Link / Android App Link — e.g. the
    // user tapped a button in an email and the app was closed. Only checked
    // once nothing above claimed the deep-link already.
    if (pendingNotificationDeepLink == null) {
      final initialUri = await AppLinks().getInitialLink();
      if (initialUri != null) {
        final notification = pushNotificationFromDeepLinkUri(initialUri);
        if (notification != null) {
          final dest = NotificationRouteResolver.resolve(
            notification,
            isGuardian: isGuardian,
            isAdminPersona: isAdminPersona,
          );
          if (dest != null) pendingNotificationDeepLink = dest.location;
          final org = (notification.organizationCode ?? '').trim();
          final school = (notification.schoolCode ?? '').trim();
          if (org.isNotEmpty && school.isNotEmpty) {
            pendingNotificationOrgSchool = {
              'organizationCode': org,
              'schoolCode': school,
            };
          }
          AppLogger.d(
            '[main] stashed (deep link) pendingNotificationDeepLink=$pendingNotificationDeepLink '
            'orgSchool=$pendingNotificationOrgSchool',
          );
        }
      }
    }
  } catch (e) {
    // Non-fatal: app still launches to its default destination.
    AppLogger.d('[main] launch-notification capture failed: $e');
  }
}
