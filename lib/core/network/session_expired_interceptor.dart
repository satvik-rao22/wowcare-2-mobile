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
  static bool _shouldIgnorePath(RequestOptions options) {
    final p = options.uri.path.toLowerCase();
    if (p.contains('/auth/login')) return true;
    if (p.contains('/auth/forgot-password')) return true;
    if (p.contains('/auth/forgot_password')) return true;
    if (p.contains('/auth/logout')) return true;
    return false;
  }
}
