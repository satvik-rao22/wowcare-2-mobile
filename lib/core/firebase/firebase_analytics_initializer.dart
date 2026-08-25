import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// iOS foreground notification presentation + FirebaseAnalytics linking.
///
/// Without [_setIosForegroundPresentationOptions], FCM messages received while
/// the app is open show NO banner, sound, or badge on iOS — they only fire
/// onMessage. [_touchFirebaseAnalytics] links the analytics library so FCM
/// doesn't log "Unable to log event: analytics library is missing" on every
/// push; collection itself stays at the Firebase console's default.
Future<void> initializeFirebaseAnalyticsAndForegroundOptions() async {
  if (Platform.isIOS) {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    debugPrint(
      '[iOS PUSH] ✅ Foreground notification presentation options set (alert/badge/sound)',
    );
  }

  try {
    FirebaseAnalytics.instance;
  } catch (_) {}
}
