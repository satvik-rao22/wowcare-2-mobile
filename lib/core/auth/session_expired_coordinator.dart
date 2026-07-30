import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_headers.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/models/logout_request_model.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/src/app_router.dart';
import 'package:provider/provider.dart';

/// When the refresh token is expired or refresh fails: call logout API, clear local
/// session, reset [AuthCubit], and navigate to sign-in.
class SessionExpiredCoordinator {
  SessionExpiredCoordinator._();
  static final SessionExpiredCoordinator instance = SessionExpiredCoordinator._();

  bool _busy = false;

  /// Best-effort backend logout (plain Dio — no auth interceptors), then clear cache
  /// and return user to sign-in.
  ///
  /// [fromSplash] bypasses the on-sign-in short-circuit for the launch path,
  /// where the splash itself detects an expired cached session (the
  /// `SessionExpiredInterceptor` ignores `/auth/login*`, so a login-context
  /// 401 never reaches it).
  Future<void> performLogoutDueToExpiredSession({
    String userMessage = 'Your session has expired. Please sign in again.',
    bool fromSplash = false,
  }) async {
    if (_busy) return;
    // Already on the sign-in screen (or no navigator yet): nothing to bounce.
    // This guard makes the coordinator safe to call on EVERY 401 — including the
    // case where the session was already cleared underneath a stuck authenticated
    // screen — without re-clearing/re-navigating and spamming the snackbar on
    // each subsequent 401.
    if (!fromSplash && _isOnSignInRoute()) return;
    _busy = true;
    try {
      final authLocal = serviceLocator<AuthLocalDataSource>();
      final cached = await authLocal.getCachedLoginResponse();

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

      await authLocal.clearCache();
      await authLocal.clearCredentials();

      final ctx = CoreUtils.rootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        try {
          ctx.read<ParentChildCubit>().invalidate();
        } catch (_) {}
        try {
          ctx.read<RoleCubit>().resetSessionForLogout();
        } catch (_) {}
        try {
          ctx.read<AuthCubit>().logout();
        } catch (_) {}
        CoreUtils.showTopSnackBar(
          context: ctx,
          message: userMessage,
          isError: true,
        );
      }
      // Reset the stack to sign-in through go_router so the current location
      // actually reflects it — that is what [_isOnSignInRoute] reads to stay
      // idempotent on any repeat 401s that land after this cascade completes.
      appRouter.go(SignInScreen.routeName);
    } finally {
      _busy = false;
    }
  }

  /// True when go_router is already sitting on the sign-in route, so a fresh
  /// session-expired signal has nothing to bounce. Any failure to read the
  /// location (router not built yet) is treated as "not on sign-in" so the
  /// logout cascade still runs and clears the cached session.
  bool _isOnSignInRoute() {
    try {
      return appRouter.routerDelegate.currentConfiguration.uri.path ==
          SignInScreen.routeName;
    } catch (_) {
      return false;
    }
  }
}
