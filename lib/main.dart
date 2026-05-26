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
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/shared/common/app/providers/theme_providers.dart';
import 'package:wowcare/shared/services/geofence_notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'package:wowcare/core/background/geofence_background_task.dart';

import 'src/app_router.dart';

/// Handle FCM messages in background (when app is not in foreground)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[FCM] Background message received: ${message.messageId}');
  print('[FCM] Title: ${message.notification?.title}');
  print('[FCM] Body: ${message.notification?.body}');
  print('[FCM] Data: ${message.data}');
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
    print('[FCM] Notification permission status: ${settings.authorizationStatus}');

    // Get FCM token — may fail on devices without Google Play Services
    try {
      final token = await messaging.getToken();
      print('[FCM] Device token: $token');
    } catch (e) {
      print('[FCM] Could not get FCM token (no Google Play Services?): $e');
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FCM] Foreground message: ${message.notification?.title}');
      try {
        serviceLocator<GeofenceNotificationService>().showCustomNotification(
          title: message.notification?.title ?? 'School Alert',
          body: message.notification?.body ?? 'You have a new notification',
        );
      } catch (e) {
        print('[FCM] Error showing notification: $e');
      }
    });

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('[FCM] Notification tapped: ${message.messageId}');
    });
  } catch (e) {
    print('[FCM] FCM setup failed (app will continue without push notifications): $e');
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => ParentChildProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final systemTextScaleFactor =
              MediaQuery.of(context).textScaler.scale(1);

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
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(customScaler)),
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
                    theme: themeProvider.currentTheme,
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
