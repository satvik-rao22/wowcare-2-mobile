import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';

// ─── Abstract contract ───────────────────────────────────────────────────────

abstract class FirebaseTokenDataSource {
  /// Register the device's FCM/APNS token with the backend.
  ///
  /// Should be called on:
  ///   - Login success
  ///   - [FirebaseMessaging.instance.onTokenRefresh]
  ///   - School / organization switch
  Future<void> registerToken({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  });
}

// ─── Implementation ──────────────────────────────────────────────────────────

const String _kLastRegisteredFcmToken = 'last_registered_fcm_token';

class FirebaseTokenDataSourceImpl implements FirebaseTokenDataSource {
  const FirebaseTokenDataSourceImpl({
    required this.apiClient,
    required this.messaging,
    required this.storage,
  });

  final ApiClient apiClient;
  final FirebaseMessaging messaging;
  final StorageService storage;

  String get _baseUrl => ApiConstants.communicationBaseUrl;

  @override
  Future<void> registerToken({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  }) async {
    final fcmToken = await messaging.getToken();
    if (fcmToken == null) return;

    // Avoid duplicate registrations for the same token + context
    final lastToken = await storage.getString(_kLastRegisteredFcmToken);
    final cacheKey = '$fcmToken|$userCode|$schoolCode';
    if (lastToken == cacheKey) return;

    final payload = <String, dynamic>{
      'fcmToken': fcmToken,
      'userCode': userCode,
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
    };

    if (Platform.isIOS) {
      final apnsToken = await messaging.getAPNSToken();
      if (apnsToken != null) payload['apnsToken'] = apnsToken;
    }

    final endpoint = ApiPaths.urlWithBase('/api/v1/firebase/token', _baseUrl);
    await apiClient.client.post(endpoint, data: payload);

    await storage.saveString(_kLastRegisteredFcmToken, cacheKey);
  }
}
