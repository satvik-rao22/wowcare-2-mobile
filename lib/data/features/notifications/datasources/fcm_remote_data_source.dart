import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // On iOS, the APNS token must be registered before FCM can issue a token.
      // Poll with a short delay so we don't throw the "apns-token-not-set" warning.
      for (int attempt = 0; attempt < 5; attempt++) {
        final apns = await _messaging.getAPNSToken();
        if (apns != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      // If APNS token still not available, return null silently (non-fatal).
      if (await _messaging.getAPNSToken() == null) return null;
    }
    return _messaging.getToken();
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

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
