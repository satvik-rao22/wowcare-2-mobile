import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/logger_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../datasources/fcm_registration_remote_data_source.dart';
import '../models/fcm_register_request_model.dart';
import '../../../../shared/common/app/providers/device_info_provider.dart';

/// Registers the device FCM token with the notification backend when a session
/// exists (user + org + school selected).
class FcmTokenRegistrationService {
  FcmTokenRegistrationService({
    required FcmRegistrationRemoteDataSource remote,
    required StorageService storage,
    DeviceInfoPlugin? deviceInfo,
  })  : _remote = remote,
        _storage = storage,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final FcmRegistrationRemoteDataSource _remote;
  final StorageService _storage;
  final DeviceInfoPlugin _deviceInfo;

  Future<void> registerToken(String fcmToken) async {
    final token = fcmToken.trim();
    if (token.isEmpty) return;

    final context = await _readSessionContext();
    if (context == null) {
      AppLogger.d(
        '[FCM] Skipping register — missing userCode, organizationCode, or schoolCode '
        '(session not ready yet; will retry after login)',
      );
      return;
    }

    try {
      final deviceId = await _resolveDeviceId();
      final deviceInfo = await getDeviceInfo();
      await _remote.register(
        FcmRegisterRequestModel(
          userCode: context.userCode,
          organizationCode: context.organizationCode,
          schoolCode: context.schoolCode,
          role: context.role,
          fcmToken: token,
          deviceType: Platform.isIOS ? 'IOS' : 'ANDROID',
          deviceId: deviceId,
          deviceInfo: deviceInfo,
        ),
      );
      AppLogger.d('[FCM] Token registered with backend for ${context.userCode}');
    } catch (e) {
      AppLogger.d('[FCM] Token registration failed (non-fatal): $e');
    }
  }

  Future<void> unregisterToken(String fcmToken) async {
    final token = fcmToken.trim();
    if (token.isEmpty) return;
    try {
      await _remote.unregisterToken(token);
      AppLogger.d('[FCM] Token unregistered from backend');
    } catch (e) {
      AppLogger.d('[FCM] Token unregister failed (non-fatal): $e');
    }
  }

  Future<_SessionContext?> _readSessionContext() async {
    final userCode =
        (await _storage.getString(StorageKeys.userCode) ?? '').trim();
    final organizationCode =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final schoolCode =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

    if (userCode.isEmpty || organizationCode.isEmpty || schoolCode.isEmpty) {
      return null;
    }

    final loginCompleted =
        await _storage.getBool(StorageKeys.loginCompleted) ?? false;
    if (!loginCompleted) {
      AppLogger.d(
        '[FCM] Session has user/org/school but loginCompleted=false — registering anyway',
      );
    }

    var role =
        (await _storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
    if (role.isEmpty) {
      role = await _roleFromRolesJson(organizationCode, schoolCode);
    }
    if (role.isEmpty) role = 'STAFF';

    return _SessionContext(
      userCode: userCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      role: role.toUpperCase(),
    );
  }

  Future<String> _roleFromRolesJson(
    String organizationCode,
    String schoolCode,
  ) async {
    final raw = await _storage.getString(StorageKeys.roles);
    if (raw == null || raw.isEmpty) return '';
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final entry in list) {
        if (entry is! Map) continue;
        final org = (entry['organizationCode'] ?? '').toString().trim();
        final school = (entry['schoolCode'] ?? '').toString().trim();
        if (org == organizationCode && school == schoolCode) {
          return (entry['role'] ?? '').toString().trim();
        }
      }
    } catch (_) {}
    return '';
  }

  Future<String> _resolveDeviceId() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return info.id;
    }
    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.identifierForVendor ?? 'unknown-ios-device';
    }
    return 'unknown-device';
  }
}

class _SessionContext {
  const _SessionContext({
    required this.userCode,
    required this.organizationCode,
    required this.schoolCode,
    required this.role,
  });

  final String userCode;
  final String organizationCode;
  final String schoolCode;
  final String role;
}
