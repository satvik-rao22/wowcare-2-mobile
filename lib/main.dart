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
import 'package:wowcare/presentation/features/notifications/cubit/push_notification_cubit.dart';
import 'package:wowcare/presentation/features/notifications/view/notification_navigator.dart';
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
