import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_headers.dart';
import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/models/logout_request_model.dart';
import 'package:wowcare/domain/features/notifications/usecases/unregister_device_fcm_token_usecase.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/forgot_password_screen.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:provider/provider.dart';

/// When the refresh token is expired or refresh fails: call logout API, clear local
/// session, reset [AuthCubit], and navigate to sign-in.
class SessionExpiredCoordinator {
  SessionExpiredCoordinator._();
  static final SessionExpiredCoordinator instance =
      SessionExpiredCoordinator._();

  bool _busy = false;

  /// Set the moment a call actually proceeds past the guards below (not on
  /// every invocation). Used to absorb a second, unrelated 401 — e.g. a
  /// background RoleCubit/notifications call that was already in flight —
  /// landing within moments of the first. [_busy] alone doesn't cover this:
  /// it resets back to false as soon as the first call's `finally` runs,
  /// which can be before go_router's `currentConfiguration` has actually
  /// settled on the sign-in route, making [_isOnPreAuthRoute] read stale.
  /// Without this, that second call slips through with its own snackbar,
  /// landing on a Sign-In screen the user hasn't touched yet — the "error
  /// shown before username/password" symptom.
  DateTime? _lastHandledAt;

  /// Routes the user can be on BEFORE they have a session: the splash (`/`,
  /// which runs its own auth check and routes), sign-in and forgot-password.
  ///
  /// The point is the fresh-install case: a stray 401 from a startup call made
  /// with no token at all (see [FirebaseAuthService.signIn]) used to bounce the
  /// user onto Login with a "session expired" error, for a session that never
  /// existed. Post-auth routes that merely look entry-ish — `/org-selection`,
  /// `/school-selection` — are deliberately NOT here: a 401 there IS a genuine
  /// expiry and must still bounce.
  static const Set<String> _preAuthRoutes = {
    '/',
    SignInScreen.routeName,
    ForgotPasswordScreen.routeName,
  };

  /// True when the app is already on a pre-auth route ([_preAuthRoutes]) or
  /// there is no navigator yet. Used to avoid a redirect/snackbar loop when a
  /// burst of 401s lands after we've already bounced the user out, and to avoid
  /// interrupting the boot/login flow.
  bool _isOnPreAuthRoute() {
    final ctx = CoreUtils.rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return true;
    try {
      final location = GoRouter.of(
        ctx,
      ).routerDelegate.currentConfiguration.uri.path;
      return _preAuthRoutes.contains(location);
    } catch (_) {
      // Router not ready — treat as "can't navigate" so we don't thrash.
      return true;
    }
  }

  /// Best-effort backend logout (plain Dio — no auth interceptors), then clear cache
  /// and return user to sign-in.
  ///
  /// [fromEntryRoute] must be true for DELIBERATE callers that run on an
  /// auth-entry route — notably the splash, which detects an expired session at
  /// route `/` and calls this to log out + route to sign-in. Without it the
  /// route guard below (meant to absorb a burst of background 401s once we've
  /// already bounced) would treat the splash's own call as a no-op and leave the
  /// app stuck on the splash.
  Future<void> performLogoutDueToExpiredSession({
    String userMessage = 'Your session has expired. Please sign in again.',
    bool fromEntryRoute = false,
  }) async {
    if (_busy) return;
    // A recent handling already bounced the user out for (almost certainly)
    // this same expired-session event — see [_lastHandledAt]'s doc comment.
    final now = DateTime.now();
    if (_lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 5)) {
      return;
    }
    // Already on a pre-auth route (or no navigator yet): nothing to bounce.
    // This guard makes the coordinator safe to call on EVERY 401 — including the
    // case where the session was already cleared underneath a stuck authenticated
    // screen — without re-clearing/re-navigating and spamming the snackbar on
    // each subsequent 401. Deliberate entry-route callers (splash) opt out.
    if (!fromEntryRoute && _isOnPreAuthRoute()) return;
    _lastHandledAt = now;
    _busy = true;
    // Before the session is cleared, so the log still carries the user.
    AppEvents.record(AppEvent.authSession, EventOutcome.expired);
    try {
      final authLocal = serviceLocator<AuthLocalDataSource>();
      final cached = await authLocal.getCachedLoginResponse();

      try {
        await serviceLocator<UnregisterDeviceFcmTokenUseCase>()();
      } catch (_) {}

      if (cached != null &&
          cached.refreshToken.isNotEmpty &&
          cached.userCode.isNotEmpty) {
        try {
          // Plain Dio (no auth interceptor) — access token may already be invalid.
          final dio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              responseType: ResponseType.json,
            ),
          );
          final body = LogoutRequestModel(
            refreshToken: cached.refreshToken,
            userCode: cached.userCode,
          );
          final logoutUrl = ApiPaths.url(ApiPaths.authLogout);
          await dio.post<dynamic>(
            logoutUrl,
            data: jsonEncode(body.toJson()),
            options: Options(headers: ApiHeaders.json),
          );
        } catch (_) {
          // Still clear local session even if logout API fails.
        }
      }

      // clearCache() preserves the "Remember me" username + flag (password is in
      // the secure store) so the sign-in form can pre-fill after a session
      // expiry. Do NOT clearCredentials() — that would break the pre-fill.
      await authLocal.clearCache();

      final ctx = CoreUtils.rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        try {
          // resetForLogout, not invalidate: an expired session must also
          // erase the PERSISTED child selection, so nothing of this parent's
          // context is left on disk for whoever signs in next.
          unawaited(ctx.read<ParentChildCubit>().resetForLogout());
        } catch (_) {}
        try {
          ctx.read<RoleCubit>().resetSessionForLogout();
        } catch (_) {}
        try {
          ctx.read<AuthCubit>().logout();
        } catch (_) {}
        // An entry-route caller (the splash's own silent "is my cached token
        // still valid" probe) fires before the user has done anything in
        // this session — showing "session expired" here reads as an error
        // on a blank Login screen instead of what it actually is (a stale
        // cached session quietly cleared). Only a genuine mid-session 401
        // via SessionExpiredInterceptor (fromEntryRoute defaults to false)
        // is worth surfacing — the user was actively using the app and got
        // logged out, which IS actionable feedback.
        if (!fromEntryRoute) {
          CoreUtils.showTopSnackBar(
            context: ctx,
            message: userMessage,
            isError: true,
          );
        }
        // Navigate via go_router (the app's router). An imperative
        // Navigator.pushAndRemoveUntil doesn't stick here because go_router
        // re-syncs to its configured location, leaving the user on the
        // previous (logged-in) screen.
        ctx.go(SignInScreen.routeName);
      }
    } finally {
      _busy = false;
    }
  }
}
