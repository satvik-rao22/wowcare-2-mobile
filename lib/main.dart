import 'package:wowcare/core/util/logger_service.dart';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:wowcare/shared/services/geofence_notification_service.dart';
// Geofence is handled via OS-level native geofencing (Android GeofencingClient, iOS region monitoring).
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

/// Setup Firebase Cloud Messaging for push notifications
Future<void> _setupFCMMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // Request notification permissions
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    AppLogger.d(
      '[FCM] Notification permission status: ${settings.authorizationStatus}',
    );

    // Get FCM token — may fail on devices without Google Play Services
    try {
      final token = await messaging.getToken();
      AppLogger.d('[FCM] Device token: $token');
    } catch (e) {
      AppLogger.d(
        '[FCM] Could not get FCM token (no Google Play Services?): $e',
      );
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.d('[FCM] Foreground message: ${message.notification?.title}');
      try {
        serviceLocator<GeofenceNotificationService>().showCustomNotification(
          title: message.notification?.title ?? 'School Alert',
          body: message.notification?.body ?? 'You have a new notification',
        );
      } catch (e) {
        AppLogger.d('[FCM] Error showing notification: $e');
      }
    });

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.d('[FCM] Notification tapped: ${message.messageId}');
    });
  } catch (e) {
    AppLogger.d(
      '[FCM] FCM setup failed (app will continue without push notifications): $e',
    );
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

  // Setup FCM messaging
  await _setupFCMMessaging();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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
                  ],
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    title: 'WowCare',
                    theme: currentTheme,
                    routerConfig: appRouter,
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
