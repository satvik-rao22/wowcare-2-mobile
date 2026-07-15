import 'package:dio/dio.dart';
import 'package:wowcare/core/auth/session_expired_coordinator.dart';

/// When the server rejects the session (e.g. access/refresh token expired), triggers
/// [SessionExpiredCoordinator] so we call logout with the stored refresh token,
/// clear local session, and return to sign-in.
class SessionExpiredInterceptor extends Interceptor {
  SessionExpiredInterceptor();

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status != 401 || _shouldIgnorePath(err.requestOptions)) {
      handler.next(err);
      return;
    }

    // Any 401 on an authenticated (non-ignored) endpoint means the session is no
    // longer valid — whether tokens are still persisted (a normal expiry) or the
    // session was already cleared underneath a still-mounted authenticated screen
    // (in which case the request goes out with no Authorization/role/school
    // headers and the server rejects it). Both must bounce the user to sign-in;
    // previously the cleared-session case bailed out silently, leaving the screen
    // stuck firing 401s forever. The coordinator no-ops when we're already on the
    // sign-in/splash route, so calling it on every such 401 is safe.
    await SessionExpiredCoordinator.instance.performLogoutDueToExpiredSession();
    handler.next(err);
  }

  /// Login/forgot-password 401 means invalid credentials, not global session expiry.
  /// Login-context 401 is handled explicitly by the splash screen (and auth cubit).
  /// FCM endpoints 401s are non-fatal and should not trigger logout.
  /// Notification operations should never interrupt authentication.
  static bool _shouldIgnorePath(RequestOptions options) {
    final p = options.uri.path.toLowerCase();
    // Auth endpoints: 401 means invalid credentials, not session expiry
    if (p.contains('/auth/login')) return true;
    if (p.contains('/auth/forgot-password')) return true;
    if (p.contains('/auth/forgot_password')) return true;
    if (p.contains('/auth/logout')) return true;
    // Login-context: 401 means the cached token expired (handled by splash screen)
    if (p.contains('/auth/login-context')) return true;
    // FCM endpoints: 401 is non-fatal and must NOT trigger logout
    if (p.contains('/notification/fcm')) return true;
    if (p.contains('/notification/fcm/')) return true;
    // Notification operations should be non-blocking
    if (p.contains('/notification/')) return true;
    return false;
  }
}
