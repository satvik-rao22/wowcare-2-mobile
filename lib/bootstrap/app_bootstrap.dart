import 'dart:async';
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
import 'package:wowcare/domain/features/activity/usecases/sweep_orphaned_staged_media_usecase.dart';

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

    _sweepOrphanedStagedMedia();
  }

  /// Deletes staged upload copies left behind by previous runs.
  ///
  /// Captures are copied into the app's documents directory before upload so
  /// Android cannot evict them mid-flight; the copy is deleted once the server
  /// confirms the upload. A process killed before that — the exact failure this
  /// staging exists to survive — leaves its copy behind with nothing left to
  /// remove it, so they are swept here.
  ///
  /// **Age is the only discriminator, and deliberately so.** The app keeps no
  /// per-file record of which staged copies belong to a live upload: the one
  /// persisted upload record (`pendingUploadPoll`) stores a session code and
  /// asset codes, carries no local path, and is a single overwritten slot
  /// rather than a set — so it cannot answer "is this file still needed?".
  /// Seven days is far longer than any upload can plausibly stay in flight,
  /// which makes deleting past it safe without such a record. If a persisted
  /// upload queue is added later, this should consult it and sweep on identity
  /// rather than age.
  ///
  /// Fire-and-forget: it touches only the app's own directory and must never
  /// delay first frame. Failures are swallowed inside the repository.
  static void _sweepOrphanedStagedMedia() {
    unawaited(
      serviceLocator<SweepOrphanedStagedMediaUseCase>()().catchError((
        Object _,
      ) {
        // Cleanup is never worth failing app start over.
        return 0;
      }),
    );
  }
}
