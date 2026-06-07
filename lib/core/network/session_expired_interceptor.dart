import 'package:dio/dio.dart';
import 'package:wowcare/core/auth/session_expired_coordinator.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';

/// When the server rejects the session (e.g. access/refresh token expired), triggers
/// [SessionExpiredCoordinator] so we call logout with the stored refresh token,
/// clear local session, and return to sign-in.
class SessionExpiredInterceptor extends Interceptor {
  SessionExpiredInterceptor(this._storage);

  final StorageService _storage;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status != 401 || _shouldIgnorePath(err.requestOptions)) {
      handler.next(err);
      return;
    }

    if (_isMissingAuthorizationHeaderError(err)) {
      await SessionExpiredCoordinator.instance.performLogoutDueToExpiredSession();
      handler.next(err);
      return;
    }

    final hasSession = await _hasAnyPersistedSessionState();
    if (!hasSession) {
      handler.next(err);
      return;
    }

    await SessionExpiredCoordinator.instance.performLogoutDueToExpiredSession();
    handler.next(err);
  }

  /// Consider the user "logged in" even when access token is unexpectedly missing,
  /// as long as any auth/session marker remains in storage.
  Future<bool> _hasAnyPersistedSessionState() async {
    final accessToken =
        (await _storage.getString(StorageKeys.accessToken) ?? '').trim();
    final refreshToken =
        (await _storage.getString(StorageKeys.refreshToken) ?? '').trim();
    final userCode = (await _storage.getString(StorageKeys.userCode) ?? '').trim();
    final loginCompleted = await _storage.getBool(StorageKeys.loginCompleted) ?? false;

    return accessToken.isNotEmpty ||
        refreshToken.isNotEmpty ||
        userCode.isNotEmpty ||
        loginCompleted;
  }

  /// Login/forgot-password 401 means invalid credentials, not global session expiry.
  /// FCM endpoints 401s are non-fatal and should not trigger logout.
  /// Notification operations should never interrupt authentication.
  static bool _shouldIgnorePath(RequestOptions options) {
    final p = options.uri.path.toLowerCase();
    // Auth endpoints: 401 means invalid credentials, not session expiry
    if (p.contains('/auth/login')) return true;
    if (p.contains('/auth/forgot-password')) return true;
    if (p.contains('/auth/forgot_password')) return true;
    if (p.contains('/auth/logout')) return true;
    // FCM endpoints: 401 is non-fatal and must NOT trigger logout
    if (p.contains('/notification/fcm')) return true;
    if (p.contains('/notification/fcm/')) return true;
    // Notification operations should be non-blocking
    if (p.contains('/notification/')) return true;
    return false;
  }

  /// Some backends return 401 with a specific message when Authorization
  /// header is absent. Treat this as a hard session-expired signal and logout.
  static bool _isMissingAuthorizationHeaderError(DioException err) {
    final data = err.response?.data;
    if (data is Map) {
      final message = (data['message'] ?? '').toString().toLowerCase();
      final error = (data['error'] ?? '').toString().toLowerCase();
      if (message.contains('missing authorization header')) return true;
      if (error == 'unauthorized' &&
          message.contains('authorization header')) {
        return true;
      }
    }
    return false;
  }
}
