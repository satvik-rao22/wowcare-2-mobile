import 'package:dio/dio.dart';
import 'package:wowcare/core/network/api_headers.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/api_paths.dart';

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

    final token = (await _storage.getString(StorageKeys.accessToken) ?? '').trim();

    // Always add baseline JSON headers. Only attach Authorization when missing.
    final baseHeaders = ApiHeaders.authorizedJson(token);
    // Normalize common JSON header casing so upstream services consistently receive them.
    options.headers['Content-Type'] =
        options.headers['Content-Type'] ??
        options.headers['content-type'] ??
        baseHeaders['Content-Type'];
    options.headers['accept'] = options.headers['accept'] ?? baseHeaders['accept'];
    if ((existingAuth == null || existingAuth.toString().trim().isEmpty) &&
        baseHeaders['Authorization'] != null) {
      options.headers['Authorization'] = baseHeaders['Authorization'];
    }

    // All services now require org/school scoping headers.
    final organizationCode =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final schoolCode =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
    final schoolCodeFromQuery =
        (options.queryParameters['schoolCode'] ?? '').toString().trim();

    final resolvedOrgCode = organizationCode;
    final resolvedSchoolCode = schoolCode.isNotEmpty
        ? schoolCode
        : schoolCodeFromQuery;

    if (resolvedOrgCode.isNotEmpty) {
      options.headers['X-Organization-Code'] = resolvedOrgCode;
      options.headers['x-organization-code'] = resolvedOrgCode;
      options.headers['organizationCode'] = resolvedOrgCode;
    }
    if (resolvedSchoolCode.isNotEmpty) {
      options.headers['X-School-Code'] = resolvedSchoolCode;
      options.headers['x-school-code'] = resolvedSchoolCode;
      options.headers['schoolCode'] = resolvedSchoolCode;
    }

    // Staff-scoped services (e.g. student MS writes) REQUIRE the acting staff
    // code header to be present. Use the cached staff code when available,
    // otherwise fall back to '-' — the org-level sentinel the app already uses
    // for org admins (see AuthCubit) — so the required header is never missing.
    final staffCode =
        (await _storage.getString(StorageKeys.staffCode) ?? '').trim();
    final staffCodeHeader = staffCode.isNotEmpty ? staffCode : '-';
    options.headers['X-Staff-Code'] = staffCodeHeader;
    options.headers['x-staff-code'] = staffCodeHeader;
    options.headers['staffCode'] = staffCodeHeader;

    handler.next(options);
  }
}
