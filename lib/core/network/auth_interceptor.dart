import 'package:dio/dio.dart';
import 'package:wowcare/core/network/api_headers.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/debug_defaults.dart';

/// Interceptor that adds Authorization Bearer token to all requests.
/// Skips auth for login, forgot-password, and other public endpoints.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final StorageService _storage;

  static final _skipAuthPaths = [
    ApiPaths.authLogin,
    ApiPaths.authForgotPassword,
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.uri.path;
    final shouldSkip = _skipAuthPaths.any((p) => path.contains(p));
    if (shouldSkip) {
      handler.next(options);
      return;
    }

    // If the request already has an explicit Authorization header (e.g. login-context
    // right after login with the fresh token), keep it and avoid overriding.
    final existingAuth =
        options.headers['Authorization'] ?? options.headers['authorization'];

    final token = await _storage.getString(StorageKeys.accessToken) ?? '';

    // Always add baseline JSON headers. Only attach Authorization when missing.
    final baseHeaders = ApiHeaders.authorizedJson(token);
    options.headers['content-type'] =
        options.headers['content-type'] ?? baseHeaders['content-type'];
    options.headers['accept'] = options.headers['accept'] ?? baseHeaders['accept'];
    if ((existingAuth == null || existingAuth.toString().trim().isEmpty) &&
        baseHeaders['Authorization'] != null) {
      options.headers['Authorization'] = baseHeaders['Authorization'];
    }

    // Attendance service requires org/school headers on every request.
    // Only attach for attendance base URL to avoid polluting other services.
    final uriString = options.uri.toString();
    final isAttendanceApi =
        uriString.startsWith(ApiConstants.attendanceBaseUrl);
    if (isAttendanceApi) {
      final organizationCode =
          await _storage.getString(StorageKeys.organizationCode);
      final schoolCode = await _storage.getString(StorageKeys.schoolCode);

      final resolvedOrgCode = (organizationCode ?? '').trim().isNotEmpty
          ? organizationCode!.trim()
          : DebugDefaults.organizationCode;
      final resolvedSchoolCode = (schoolCode ?? '').trim().isNotEmpty
          ? schoolCode!.trim()
          : DebugDefaults.schoolCode;

      if (resolvedOrgCode.isNotEmpty) {
        options.headers['X-Organization-Code'] = resolvedOrgCode;
      }
      if (resolvedSchoolCode.isNotEmpty) {
        options.headers['X-School-Code'] = resolvedSchoolCode;
      }
    }

    handler.next(options);
  }
}
