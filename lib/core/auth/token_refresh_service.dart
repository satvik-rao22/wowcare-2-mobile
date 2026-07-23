import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/network/api_headers.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';

/// Renews the access token via `POST /api/v1/user/auth/refresh`, mirroring the
/// web client's `refreshSession()`.
///
/// **Wire-identical to web.** The web refresh token is a plain JS-set cookie
/// (not httpOnly), so the client already holds the value at login and
/// `credentials: 'include'` is just the browser echoing it back. Mobile does the
/// same thing explicitly: `Cookie: refreshToken=<urlencoded>` with an empty
/// `{}` body. No backend change required, and it matches a request shape that's
/// already proven in production.
///
/// The one deliberate difference: mobile keeps the token in the Keychain /
/// EncryptedSharedPreferences rather than a JS-readable cookie or plain
/// SharedPreferences.
///
/// The four invariants carried over from web — all of them load-bearing:
///  1. Refresh must never recurse into itself. Achieved by exempting
///     `/auth/refresh` inside the interceptors rather than by forking a second
///     [Dio] — see [_dio] for why, and for the three guards that enforce it.
///  2. Single-flight: the in-flight marker is registered BEFORE the first
///     `await`, so N parallel 401s share ONE refresh. The server rotates the
///     refresh token, so concurrent refreshes would present an already-consumed
///     token and log the user out — a bug that looks random and is miserable to
///     reproduce.
///  3. The marker is cleared on failure too, or one failed refresh poisons every
///     future attempt for the life of the process.
///  4. A rotated refresh token from the response is persisted, otherwise the
///     next refresh presents a consumed token and fails hours later.
class TokenRefreshService {
  TokenRefreshService._();
  static final TokenRefreshService instance = TokenRefreshService._();

  /// The app's single [Dio]. Refresh does NOT fork its own client: a second
  /// client means hand-copying the header contract, which silently rots the day
  /// a globally-required header is added — presenting as this exact mystery 401.
  ///
  /// Recursion is prevented by exemption instead, and it's triple-guarded:
  ///  • [AuthInterceptor] skips `/auth/refresh` (no Authorization, no context
  ///    headers — keeps it on the gateway's relaxed path);
  ///  • [SessionExpiredInterceptor] ignores `/auth/refresh`, so a dead refresh
  ///    token can never trigger refresh-on-refresh;
  ///  • `validateStatus: (_) => true` means a 401 here isn't even raised as a
  ///    DioException, so the error interceptor never runs for it.
  Dio get _dio => serviceLocator<ApiClient>().client;

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Secure-store key for the refresh token.
  static const String _kRefreshToken = 'auth_refresh_token';

  Completer<String?>? _inFlight;

  /// One-shot guard for the legacy-session expiry backfill (see
  /// [ensureFreshToken]).
  bool _expiryBackfillAttempted = false;

  StorageService get _storage => serviceLocator<StorageService>();

  // ── token storage ────────────────────────────────────────────────────────

  /// Persists the refresh token in the secure store. Also mirrored into
  /// [StorageKeys.refreshToken] because the logout call and the session checks
  /// still read it from there.
  Future<void> saveRefreshToken(String token) async {
    final t = token.trim();
    if (t.isEmpty) return;
    try {
      await _secure.write(key: _kRefreshToken, value: t);
    } catch (e) {
      AppLogger.d('[TokenRefresh] secure write failed: $e');
    }
    await _storage.saveString(StorageKeys.refreshToken, t);
  }

  /// Reads the refresh token, preferring the secure store and falling back to
  /// SharedPreferences for sessions created before secure storage was added.
  Future<String> readRefreshToken() async {
    try {
      final secure = (await _secure.read(key: _kRefreshToken) ?? '').trim();
      if (secure.isNotEmpty) return secure;
    } catch (e) {
      AppLogger.d('[TokenRefresh] secure read failed: $e');
    }
    return (await _storage.getString(StorageKeys.refreshToken) ?? '').trim();
  }

  /// Records the absolute deadline for an `expiresIn` (seconds) duration.
  Future<void> saveAccessTokenExpiry(int expiresInSeconds) async {
    if (expiresInSeconds <= 0) return;
    final deadline = DateTime.now().add(Duration(seconds: expiresInSeconds));
    await _storage.saveInt(
      StorageKeys.tokenExpiresAt,
      deadline.millisecondsSinceEpoch,
    );
  }

  Future<void> clear() async {
    try {
      await _secure.delete(key: _kRefreshToken);
    } catch (_) {}
    await _storage.remove(StorageKeys.tokenExpiresAt);
  }

  // ── refresh ──────────────────────────────────────────────────────────────

  /// Single-flight refresh. Returns the new access token, or null on any
  /// failure. Never throws — callers treat null as "session is gone".
  Future<String?> refreshSession() {
    final existing = _inFlight;
    if (existing != null) return existing.future;

    // Registered synchronously, before any await (invariant 2).
    final completer = Completer<String?>();
    _inFlight = completer;

    _doRefresh().then((token) {
      _inFlight = null; // cleared on success…
      completer.complete(token);
    }).catchError((Object e) {
      _inFlight = null; // …and on failure (invariant 3).
      AppLogger.d('[TokenRefresh] refresh threw: $e');
      completer.complete(null);
    });

    return completer.future;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await readRefreshToken();
    if (refreshToken.isEmpty) {
      AppLogger.d('[TokenRefresh] no refresh token stored');
      return null;
    }

    final url = ApiPaths.url(ApiPaths.authRefresh);
    final response = await _dio.post<dynamic>(
      url,
      // Empty body — the cookie is the credential, exactly as on web.
      data: const <String, dynamic>{},
      options: Options(
        headers: <String, String>{
          // Content-Type + accept only. Notably NO x-sub-channel: its presence
          // is what opts the request into the gateway's strict header matrix
          // (see AuthInterceptor's exemption), and a PARTIAL strict set is 4xx'd.
          ...ApiHeaders.json,
          // What `credentials: 'include'` does in the browser. The web cookie is
          // JS-set (not httpOnly), so we hold the same value and echo it back.
          'Cookie': 'refreshToken=${Uri.encodeComponent(refreshToken)}',
        },
        // Inspect the status ourselves rather than throwing.
        validateStatus: (_) => true,
      ),
    );

    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      AppLogger.d('[TokenRefresh] refresh failed: HTTP $status');
      return null;
    }

    // Defensive unwrapping, matching web's `json?.data ?? json`: tolerate both
    // a `data`-wrapped and a flat body.
    final root = response.data;
    if (root is! Map) return null;
    final body = (root['data'] is Map ? root['data'] as Map : root);

    final newAccess =
        (body['accessToken'] ?? body['token'] ?? body['access_token'] ?? '')
            .toString()
            .trim();
    if (newAccess.isEmpty) {
      AppLogger.d('[TokenRefresh] response carried no access token');
      return null;
    }

    await _storage.saveString(StorageKeys.accessToken, newAccess);

    // Invariant 4 — persist a rotated refresh token when one comes back.
    //
    // With the cookie form the server most likely rotates via `Set-Cookie`
    // rather than in the JSON body (that's what the browser would silently
    // absorb), so check BOTH. Missing the rotation is the worst class of bug
    // here: the next refresh presents a consumed token and the user is logged
    // out hours later, seemingly at random.
    final rotated =
        (body['refreshToken'] ?? body['refresh_token'] ?? '').toString().trim();
    final rotatedCookie = _refreshTokenFromSetCookie(response.headers);
    final newRefresh = rotated.isNotEmpty ? rotated : rotatedCookie;
    if (newRefresh.isNotEmpty && newRefresh != refreshToken) {
      AppLogger.d('[TokenRefresh] refresh token rotated — persisting');
      await saveRefreshToken(newRefresh);
    }

    final expiresIn = _toInt(body['expiresIn'] ?? body['expires_in']);
    if (expiresIn > 0) {
      await _storage.saveInt(StorageKeys.tokenExpiresIn, expiresIn);
      await saveAccessTokenExpiry(expiresIn);
    }

    AppLogger.d('[TokenRefresh] access token renewed (expiresIn=${expiresIn}s)');
    return newAccess;
  }

  /// Proactive refresh — the piece the web doesn't need. A browser tab stays
  /// alive; a phone backgrounds for hours and the token is stale on resume, so
  /// refresh BEFORE the first request instead of eating a guaranteed 401.
  ///
  /// [skew] refreshes just before the deadline, avoiding the race where a token
  /// valid for another 200ms passes the check and 401s anyway.
  ///
  /// Returns true when a usable access token is in place afterwards.
  Future<bool> ensureFreshToken({
    Duration skew = const Duration(seconds: 60),
  }) async {
    final accessToken =
        (await _storage.getString(StorageKeys.accessToken) ?? '').trim();
    if (accessToken.isEmpty) return false;

    final expiryMs = await _storage.getInt(StorageKeys.tokenExpiresAt);
    if (expiryMs == null || expiryMs <= 0) {
      // Session created before this build has no recorded deadline. Backfill it
      // with ONE refresh so these users get proactive refresh from their next
      // launch instead of their next login. Guarded to once per process: if the
      // response carries no `expiresIn`, expiresAt stays null and we must not
      // re-refresh on every resume.
      if (_expiryBackfillAttempted) return true;
      _expiryBackfillAttempted = true;
      if ((await readRefreshToken()).isEmpty) return true;
      AppLogger.d('[TokenRefresh] no expiry recorded — backfilling once');
      return (await refreshSession()) != null;
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    if (DateTime.now().add(skew).isBefore(expiresAt)) return true;

    AppLogger.d('[TokenRefresh] token expired/expiring — refreshing on resume');
    return (await refreshSession()) != null;
  }

  /// Extracts a rotated `refreshToken` from the response's `Set-Cookie`
  /// headers, or '' when absent. Values are URL-decoded to mirror how they were
  /// sent. A browser would absorb this automatically; on mobile we have to.
  static String _refreshTokenFromSetCookie(Headers headers) {
    final cookies = headers.map['set-cookie'] ?? const <String>[];
    for (final raw in cookies) {
      for (final part in raw.split(';')) {
        final segment = part.trim();
        if (!segment.toLowerCase().startsWith('refreshtoken=')) continue;
        final value = segment.substring('refreshToken='.length).trim();
        if (value.isEmpty) continue;
        try {
          return Uri.decodeComponent(value);
        } catch (_) {
          return value; // not encoded — take it as-is
        }
      }
    }
    return '';
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}'.trim()) ?? 0;
  }
}
