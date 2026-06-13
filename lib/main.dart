import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/notification_payload.dart';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/theme_cubit.dart';
// Geofence is handled via OS-level native geofencing (Android GeofencingClient, iOS region monitoring).
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/presentation/features/notifications/cubit/push_notification_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_attendance_cubit_v2.dart';
import 'package:wowcare/presentation/features/notifications/view/notification_navigator.dart';
import 'package:wowcare/data/features/notifications/models/push_notification_model.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';
import 'src/app_router.dart';

/// Handle FCM messages in background / terminated state.
///
/// Runs in a separate Dart isolate — no DI, no service locator available.
/// For notification messages (FCM payload has a `notification` field) Android
/// already shows the system tray notification automatically; we only need to
/// act on data-only messages which Android silently drops without this handler.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  AppLogger.d('[FCM] ════════ Background notification received ════════');
  AppLogger.d('[FCM] messageId : ${message.messageId}');
  AppLogger.d('[FCM] from      : ${message.from}');
  AppLogger.d('[FCM] title     : ${message.notification?.title}');
  AppLogger.d('[FCM] body      : ${message.notification?.body}');
  AppLogger.d('[FCM] android   : ${message.notification?.android}');
  AppLogger.d('[FCM] data      : ${message.data}');
  AppLogger.d('[FCM] ═══════════════════════════════════════════════════');

  // Data-only messages: Android doesn't show anything automatically.
  // Show a local notification so the user always sees the alert.
  if (message.notification == null) {
    final title = message.data['title']?.toString() ?? 'WowCare';
    final body =
        message.data['body']?.toString() ?? 'You have a new notification';
    AppLogger.d('[FCM] Background data-only → showing local notif "$title"');

    // Keep in sync with GeofenceNotificationService.pushChannelId / the
    // AndroidManifest's default_notification_channel_id so every push uses one
    // audible, high-importance channel.
    const channelId = 'wowcare_alerts_v2';
    const channelName = 'WowCare Notifications';

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher_foreground'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );
    await plugin.show(
      id: message.messageId.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
    );
  }
}

/// Native bridge to read the FCM `data` payload of the notification that
/// cold-launched the app (killed state) — a reliable fallback for
/// FirebaseMessaging.getInitialMessage() returning null with our manual plugin
/// registration. See MainActivity.consumeLaunchNotificationData().
const MethodChannel _notificationChannel = MethodChannel(
  'wowcare/notifications',
);

Future<Map<String, String>?> _readNativeLaunchNotification() async {
  try {
    final raw = await _notificationChannel.invokeMapMethod<String, dynamic>(
      'getInitialNotificationData',
    );
    if (raw == null) return null;
    return raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  } catch (_) {
    return null;
  }
}

/// iOS only: reads the action stored by AppDelegate when the user tapped a
/// native geofence UNNotification from the killed/background state.
/// Returns e.g. {'action': 'GEOFENCE_ENTER'}, or null.
Future<Map<String, String>?> _readIosGeofenceTap() async {
  if (!Platform.isIOS) return null;
  try {
    const ch = MethodChannel('wowcare/geofence_tap');
    final action = await ch.invokeMethod<String>('getPendingAction');
    if (action == null || action.isEmpty) return null;
    return {'action': action};
  } catch (_) {
    return null;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  await configureDependencies();

  await Firebase.initializeApp();

  // iOS foreground notifications: without this call FCM messages received while
  // the app is open show NO banner, sound, or badge — they only fire onMessage.
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[iOS PUSH] ✅ Foreground notification presentation options set (alert/badge/sound)');
  }

  // Touch FirebaseAnalytics so the analytics library is linked and registered —
  // FCM otherwise logs "Unable to log event: analytics library is missing" on
  // every push. Collection itself stays at the Firebase console's default.
  try {
    FirebaseAnalytics.instance;
  } catch (_) {}

  // Register the background/terminated isolate handler (must be a top-level
  // function). Foreground messages, token and tap-navigation are owned by
  // PushNotificationCubit, wired up via NotificationNavigator at the app root.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Create the default FCM notification channel up-front so it exists before any
  // notification-type push arrives. The AndroidManifest references this id as
  // `default_notification_channel_id`; without the channel existing, Android logs
  // "Missing Default Notification Channel metadata".
  if (Platform.isAndroid) {
    try {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'wowcare_alerts_v2',
              'WowCare Notifications',
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );
    } catch (_) {
      // Non-fatal: notifications still arrive on the system default channel.
    }
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Killed-state launch: if a notification tap cold-started the app, capture and
  // resolve it to a deep-link NOW — before any UI builds — so the splash routes
  // there instead of the dashboard. Doing this in main() (rather than in the
  // cubit's post-frame init) removes any race with the splash's auth timer.
  try {
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
      launchData = await _readNativeLaunchNotification();
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
      final geofenceTapData = await _readIosGeofenceTap();
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
        );
        if (dest != null) pendingNotificationDeepLink = dest.location;
        AppLogger.d(
          '[main] stashed (iOS geofence tap) pendingNotificationDeepLink=$pendingNotificationDeepLink',
        );
      }
    }
  } catch (e) {
    // Non-fatal: app still launches to its default destination.
    AppLogger.d('[main] launch-notification capture failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<RoleCubit>(create: (_) => RoleCubit()),
        BlocProvider<ParentChildCubit>(
          create: (_) => serviceLocator<ParentChildCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, currentTheme) {
          final systemTextScaleFactor = MediaQuery.of(
            context,
          ).textScaler.scale(1);

          double customScaler;
          if (systemTextScaleFactor < 0.85) {
            customScaler = 0.8;
          } else if (systemTextScaleFactor < 1.0) {
            customScaler = 0.9;
          } else if (systemTextScaleFactor < 1.2) {
            customScaler = 1.0;
          } else if (systemTextScaleFactor < 1.5) {
            customScaler = 1.1;
          } else {
            customScaler = 1.2;
          }

          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(customScaler)),
            child: Sizer(
              builder: (context, orientation, screenType) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider<AuthCubit>(
                      create: (_) => serviceLocator<AuthCubit>()..initialize(),
                    ),
                    BlocProvider<PushNotificationCubit>(
                      create: (_) => serviceLocator<PushNotificationCubit>(),
                    ),
                    BlocProvider<GeofenceCubit>(
                      create: (_) => serviceLocator<GeofenceCubit>(),
                    ),
                    // Kiosk cubits provided at app root so all routes have access
                    // This fixes ProviderNotFoundException in GoRouter nested routes
                    BlocProvider<KioskDashboardCubit>(
                      create: (_) => serviceLocator<KioskDashboardCubit>(),
                    ),
                    BlocProvider<KioskAttendanceCubitV2>(
                      create: (_) => serviceLocator<KioskAttendanceCubitV2>(),
                    ),
                  ],
                  child: NotificationNavigator(
                    child: MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      title: 'WowCare',
                      theme: currentTheme,
                      routerConfig: appRouter,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
