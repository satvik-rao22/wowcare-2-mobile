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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (status != 401 || _shouldIgnorePath(err.requestOptions)) {
      handler.next(err);
      return;
    }

    _storage.getString(StorageKeys.accessToken).then((token) {
      final hasSession = (token ?? '').trim().isNotEmpty;
      if (!hasSession) {
        handler.next(err);
        return;
      }
      SessionExpiredCoordinator.instance
          .performLogoutDueToExpiredSession()
          .whenComplete(() => handler.next(err));
    });
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
