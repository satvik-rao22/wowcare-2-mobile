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
    // right after login with the fresh token), do not overwrite it with storage.
    final existingAuth = options.headers['Authorization'] ?? options.headers['authorization'];
    if (existingAuth != null && existingAuth.toString().trim().isNotEmpty) {
      handler.next(options);
      return;
    }

    final token = await _storage.getString(StorageKeys.accessToken);
    final headers = ApiHeaders.authorizedJson(token ?? '');
    options.headers.addAll(headers);
    handler.next(options);
  }
}
