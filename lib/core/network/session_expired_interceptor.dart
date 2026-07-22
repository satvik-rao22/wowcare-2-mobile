import 'package:dio/dio.dart';
import 'package:wowcare/core/auth/session_expired_coordinator.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/core/util/logger_service.dart';

/// Handles 401s: first try to RENEW the session, and only log the user out if
/// renewal isn't possible.
///
/// Mirrors the web client's 401 interceptor — refresh, then replay the original
/// request once; a second consecutive 401 falls through to logout. Without the
/// retry-once guard, a token the server rejects for a non-expiry reason
/// (revoked, wrong scope) would loop forever.
class SessionExpiredInterceptor extends Interceptor {
  SessionExpiredInterceptor(this._dio);

  /// The client this interceptor is attached to — used to replay the original
  /// request after a successful refresh.
  final Dio _dio;

  /// Marks a request that has already been retried after a refresh, so it can
  /// never be retried again. Dio's equivalent of the web's threaded
  /// `__retried` fetch-option.
  static const String _retriedFlag = '__retried';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status != 401 || _shouldIgnorePath(err.requestOptions)) {
      handler.next(err);
      return;
    }

    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
    if (!alreadyRetried) {
      final newToken = await TokenRefreshService.instance.refreshSession();
      if (newToken != null && newToken.isNotEmpty) {
        try {
          final options = err.requestOptions
            ..extra[_retriedFlag] = true
            ..headers['Authorization'] = 'Bearer $newToken';
          final replayed = await _dio.fetch<dynamic>(options);
          handler.resolve(replayed);
          return;
        } on DioException catch (replayError) {
          // The refresh SUCCEEDED — the session is valid and the new token is
          // stored. Only this one replay failed (network blip, timeout, or a
          // second 401 the nested pass already handled). Logging out here would
          // kill a healthy session over a transient failure.
          //
          // Surface the REPLAY's error, not the original 401: propagating the
          // stale 401 would tell every caller "session dead" for what was
          // actually a network failure — the same mistake, one layer down.
          AppLogger.d('[TokenRefresh] replay after refresh failed: $replayError');
          handler.next(replayError);
          return;
        } catch (e) {
          AppLogger.d('[TokenRefresh] replay after refresh threw: $e');
          handler.next(
            DioException(
              requestOptions: err.requestOptions,
              error: e,
              type: DioExceptionType.unknown,
            ),
          );
          return;
        }
      }
    }

    // Renewal wasn't possible (no/expired refresh token, or a second 401 on the
    // replay). Any 401 on an authenticated endpoint at this point means the
    // session is genuinely gone — whether tokens are still persisted (a normal
    // expiry) or the session was already cleared underneath a still-mounted
    // authenticated screen (in which case the request goes out with no
    // Authorization/role/school headers and the server rejects it). Both must
    // bounce the user to sign-in; previously the cleared-session case bailed out
    // silently, leaving the screen stuck firing 401s forever. The coordinator
    // no-ops when we're already on the sign-in/splash route, so calling it on
    // every such 401 is safe.
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
    // The refresh call itself: a 401 here means the refresh token is dead. It
    // must NOT re-enter refresh (infinite recursion) — the caller already
    // handles a null result by logging out.
    if (p.contains('/auth/refresh')) return true;
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
