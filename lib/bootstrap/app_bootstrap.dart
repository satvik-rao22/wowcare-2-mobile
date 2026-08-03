import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/background/workmanager_initializer.dart';
import 'package:wowcare/core/configuration/device_configuration.dart';
import 'package:wowcare/core/firebase/firebase_analytics_initializer.dart';
import 'package:wowcare/core/firebase/firebase_background_handler.dart';
import 'package:wowcare/core/firebase/firebase_initializer.dart';
import 'package:wowcare/core/notifications/notification_channel_service.dart';
import 'package:wowcare/core/notifications/notification_launch_handler.dart';
import 'package:wowcare/core/security/fresh_install_reset_service.dart';

/// Orchestrates all app startup steps, in the exact order the app previously
/// ran them from `main()`, before the widget tree is built with `runApp`.
class AppBootstrap {
  static Future<void> initialize() async {
    initializeTimeZoneData();

    await configureDependencies();

    // One-time WorkManager setup. Registers the callback dispatcher only —
    // does NOT schedule any task. Task registration/cancellation is entirely
    // state-driven from GeofenceCubit (always + gpsSignInEnabled only).
    await initializeWorkManager();

    // Fresh-install reset: iOS Keychain (flutter_secure_storage) SURVIVES app
    // uninstall, so a reinstall could keep old "Remember me" credentials. The
    // install marker lives in SharedPreferences (wiped on uninstall); if it's
    // absent, this is a fresh install → wipe the Keychain so the app opens clean.
    await resetSecureStoreOnFreshInstall();

    await ensureFirebaseInitialized();

    // iOS foreground notifications + FirebaseAnalytics library linking.
    await initializeFirebaseAnalyticsAndForegroundOptions();

    // Register the background/terminated isolate handler (must be a top-level
    // function). Foreground messages, token and tap-navigation are owned by
    // PushNotificationCubit, wired up via NotificationNavigator at the app root.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Create the default FCM notification channel up-front so it exists before any
    // notification-type push arrives. The AndroidManifest references this id as
    // `default_notification_channel_id`; without the channel existing, Android logs
    // "Missing Default Notification Channel metadata".
    if (Platform.isAndroid) {
      try {
        await createDefaultNotificationChannel(FlutterLocalNotificationsPlugin());
      } catch (_) {
        // Non-fatal: notifications still arrive on the system default channel.
      }
    }

    setPreferredOrientations();

    await resolvePendingLaunchNotification();
  }
}
