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
    // TEMP: Disable Authorization header for all requests so APIs are called without token.
    //
    // We still want basic JSON headers (content-type / accept), but we do NOT
    // attach any Bearer token, regardless of endpoint or stored access token.
    //
    // If you want to re‑enable auth later, restore the previous logic that:
    //   - skips some auth paths
    //   - reads the token from storage
    //   - uses ApiHeaders.authorizedJson(token) to add Authorization.
    options.headers.addAll(ApiHeaders.json);
    handler.next(options);
  }
}
