import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_headers.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/models/logout_request_model.dart';
import 'package:wowcare/domain/features/notifications/usecases/unregister_device_fcm_token_usecase.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/auth/view/sign_in_screen.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:provider/provider.dart';

/// When the refresh token is expired or refresh fails: call logout API, clear local
/// session, reset [AuthCubit], and navigate to sign-in.
class SessionExpiredCoordinator {
  SessionExpiredCoordinator._();
  static final SessionExpiredCoordinator instance = SessionExpiredCoordinator._();

  bool _busy = false;

  /// Best-effort backend logout (plain Dio — no auth interceptors), then clear cache
  /// and return user to sign-in.
  Future<void> performLogoutDueToExpiredSession({
    String userMessage = 'Your session has expired. Please sign in again.',
  }) async {
    if (_busy) return;
    _busy = true;
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
        Navigator.of(ctx, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
          (_) => false,
        );
      }
    } finally {
      _busy = false;
    }
  }
}
