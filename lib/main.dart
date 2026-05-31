import 'package:wowcare/core/util/logger_service.dart';
import 'dart:io';

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
import 'package:wowcare/presentation/features/notifications/cubit/push_notification_cubit.dart';
import 'package:wowcare/presentation/features/notifications/view/notification_navigator.dart';
import 'package:wowcare/data/features/notifications/models/push_notification_model.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';
import 'package:workmanager/workmanager.dart';
import 'package:wowcare/core/background/geofence_background_task.dart';
import 'src/app_router.dart';

/// Handle FCM messages in background (when app is not in foreground)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.d('[FCM] Background message received: ${message.messageId}');
  AppLogger.d('[FCM] Title: ${message.notification?.title}');
  AppLogger.d('[FCM] Body: ${message.notification?.body}');
  AppLogger.d('[FCM] Data: ${message.data}');
}

/// Native bridge to read the FCM `data` payload of the notification that
/// cold-launched the app (killed state) — a reliable fallback for
/// FirebaseMessaging.getInitialMessage() returning null with our manual plugin
/// registration. See MainActivity.consumeLaunchNotificationData().
const MethodChannel _notificationChannel =
    MethodChannel('wowcare/notifications');

Future<Map<String, String>?> _readNativeLaunchNotification() async {
  try {
    final raw = await _notificationChannel
        .invokeMapMethod<String, dynamic>('getInitialNotificationData');
    if (raw == null) return null;
    return raw.map((k, v) => MapEntry(k, v?.toString() ?? ''));
  } catch (_) {
    return null;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  await configureDependencies();

  if (Platform.isIOS) {
    await Firebase.initializeApp();
  } else {
    // Android Firebase initialization
    await Firebase.initializeApp();
  }

  // Register the background/terminated isolate handler (must be a top-level
  // function). Foreground messages, token and tap-navigation are owned by
  // PushNotificationCubit, wired up via NotificationNavigator at the app root.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize WorkManager for background geofence checks
  await Workmanager().initialize(geofenceBackgroundCallback);
  // Schedule periodic geofence check (15-minute minimum on Android)
  await Workmanager().registerPeriodicTask(
    'geofence_check',
    'geofenceCheckTask',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

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
      AppLogger.d('[main] stashed pendingNotificationDeepLink=$pendingNotificationDeepLink');
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
        pendingNotificationDeepLink = payload;
        AppLogger.d('[main] stashed (local notif) pendingNotificationDeepLink=$pendingNotificationDeepLink');
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
        BlocProvider<ParentChildCubit>(create: (_) => ParentChildCubit()),
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
