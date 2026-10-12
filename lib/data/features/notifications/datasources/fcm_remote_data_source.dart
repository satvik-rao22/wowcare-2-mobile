import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/core/utils/logger_service.dart';

import '../models/push_notification_model.dart';

/// Thin wrapper over [FirebaseMessaging] so the repository depends on our seam
/// rather than the SDK directly (keeps the rest of the app testable).
abstract class FcmRemoteDataSource {
  Future<void> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<PushNotificationModel> get onMessage;
  Stream<PushNotificationModel> get onNotificationTap;
  Future<PushNotificationModel?> getInitialMessage();
}

class FcmRemoteDataSourceImpl implements FcmRemoteDataSource {
  FcmRemoteDataSourceImpl(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
    );

    if (Platform.isIOS) {
      AppLogger.d('[iOS PUSH] Permission status: ${settings.authorizationStatus}');
      AppLogger.d('[iOS PUSH]   alert  : ${settings.alert}');
      AppLogger.d('[iOS PUSH]   badge  : ${settings.badge}');
      AppLogger.d('[iOS PUSH]   sound  : ${settings.sound}');
      AppLogger.d('[iOS PUSH]   announcement: ${settings.announcement}');

      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          AppLogger.d('[iOS PUSH] ✅ User granted full notification permission');
        case AuthorizationStatus.provisional:
          AppLogger.d('[iOS PUSH] ⚠️  User granted provisional notification permission');
        case AuthorizationStatus.denied:
          AppLogger.w('[iOS PUSH] ❌ User denied notification permission');
        case AuthorizationStatus.notDetermined:
          AppLogger.d('[iOS PUSH] ⏳ Notification permission not yet determined');
      }
    }
  }

  @override
  Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // APNS token must be registered with Apple before FCM can issue a token.
      // Poll up to 5 times with 1 s gaps; APNS registration is async and may
      // not be ready immediately after app launch.
      String? apnsToken;
      for (int attempt = 1; attempt <= 5; attempt++) {
        apnsToken = await _messaging.getAPNSToken();
        AppLogger.d('[iOS APNS] Attempt $attempt/5 → ${apnsToken != null ? "✅ token received" : "⏳ not yet available"}');
        if (apnsToken != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      if (apnsToken == null) {
        AppLogger.w('[iOS APNS] ❌ APNS token not available after 5 attempts — push notifications will not work');
        AppLogger.d('[iOS APNS]    Check: Push Notifications capability enabled in Apple Developer portal?');
        AppLogger.d('[iOS APNS]    Check: aps-environment entitlement present in Runner.entitlements?');
        AppLogger.d('[iOS APNS]    Check: Device connected to internet and signed into iCloud?');
        return null;
      }

      AppLogger.d('[iOS APNS] ✅ APNS token: $apnsToken');
    }

    final fcmToken = await _messaging.getToken();
    if (Platform.isIOS) {
      if (fcmToken != null) {
        AppLogger.d('[iOS FCM] ✅ FCM token obtained: $fcmToken');
      } else {
        AppLogger.w('[iOS FCM] ❌ FCM token is null — check Firebase project configuration');
      }
    }
    return fcmToken;
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh.map((token) {
    if (Platform.isIOS) {
      AppLogger.d('[iOS FCM] 🔄 Token refreshed: $token');
    }
    return token;
  });

  @override
  Stream<PushNotificationModel> get onMessage =>
      FirebaseMessaging.onMessage.map(PushNotificationModel.fromRemoteMessage);

  @override
  Stream<PushNotificationModel> get onNotificationTap =>
      FirebaseMessaging.onMessageOpenedApp
          .map(PushNotificationModel.fromRemoteMessage);

  @override
  Future<PushNotificationModel?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) return null;
    return PushNotificationModel.fromRemoteMessage(message);
  }
}
