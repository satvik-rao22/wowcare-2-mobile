import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/network/api_headers.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

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

  /// Root view of the app's secure store — deliberately NOT the `app`
  /// namespace behind [StorageService], so `StorageService.clear()` on
  /// logout cannot touch these keys; [clear] below owns them.
  SecureStorage get _secure => serviceLocator<SecureStorage>();

  /// Secure-store key for the refresh token.
  static const String _kRefreshToken = 'auth_refresh_token';

  /// Secure-store key for the access token.
  static const String _kAccessToken = 'auth_access_token';

  Completer<String?>? _inFlight;

  /// One-shot guard for the legacy-session expiry backfill (see
  /// [ensureFreshToken]).
  bool _expiryBackfillAttempted = false;

  StorageService get _storage => serviceLocator<StorageService>();

  // ── token storage ────────────────────────────────────────────────────────
  //
  // Both tokens live under their own root-level keys in the secure store. The
  // reads below still promote any value left under the legacy StorageService
  // keys (a session created before tokens moved out of the general store)
  // into these keys once and delete the old copy — so existing users are not
  // logged out on update.

  /// Persists the refresh token in the secure store.
  Future<void> saveRefreshToken(String token) async {
    final t = token.trim();
    if (t.isEmpty) return;
    try {
      await _secure.writeString(_kRefreshToken, t);
    } catch (e) {
      AppLogger.d('[TokenRefresh] secure refresh write failed: $e');
    }
  }

  /// Reads the refresh token from the secure store, one-time migrating a legacy
  /// plaintext value into it (then clearing the plaintext copy).
  Future<String> readRefreshToken() async {
    try {
      final secure = (await _secure.readString(_kRefreshToken) ?? '').trim();
      if (secure.isNotEmpty) return secure;
    } catch (e) {
      AppLogger.d('[TokenRefresh] secure refresh read failed: $e');
    }
    return _migrateLegacyPlaintext(StorageKeys.refreshToken, _kRefreshToken);
  }

  /// Persists the access token in the secure store.
  Future<void> saveAccessToken(String token) async {
    final t = token.trim();
    if (t.isEmpty) return;
    try {
      await _secure.writeString(_kAccessToken, t);
    } catch (e) {
      AppLogger.d('[TokenRefresh] secure access write failed: $e');
    }
  }

  /// Reads the access token from the secure store, one-time migrating a legacy
  /// plaintext value into it (then clearing the plaintext copy).
  Future<String> readAccessToken() async {
    try {
      final secure = (await _secure.readString(_kAccessToken) ?? '').trim();
      if (secure.isNotEmpty) return secure;
    } catch (e) {
      AppLogger.d('[TokenRefresh] secure access read failed: $e');
    }
    return _migrateLegacyPlaintext(StorageKeys.accessToken, _kAccessToken);
  }

  /// Promotes a legacy plaintext token ([plaintextKey]) into the secure store
  /// ([secureKey]) exactly once, deletes the plaintext copy, and returns the
  /// value. Returns '' when there is nothing to migrate.
  Future<String> _migrateLegacyPlaintext(
    String plaintextKey,
    String secureKey,
  ) async {
    final legacy = (await _storage.getString(plaintextKey) ?? '').trim();
    if (legacy.isEmpty) return '';
    try {
      await _secure.writeString(secureKey, legacy);
      await _storage.remove(plaintextKey);
    } catch (e) {
      AppLogger.d('[TokenRefresh] legacy token migration failed: $e');
    }
    return legacy;
  }

  /// Records the absolute deadline for an `expiresIn` (seconds) duration.
  Future<void> saveAccessTokenExpiry(int expiresInSeconds) async {
    if (expiresInSeconds <= 0) return;
    final deadline = AppTime.nowUtc().add(Duration(seconds: expiresInSeconds));
    await _storage.saveInt(
      StorageKeys.tokenExpiresAt,
      deadline.millisecondsSinceEpoch,
    );
  }

  Future<void> clear() async {
    try {
      await _secure.delete(_kRefreshToken);
      await _secure.delete(_kAccessToken);
    } catch (_) {}
    await _storage.remove(StorageKeys.tokenExpiresAt);
    // Purge any legacy plaintext copies from pre-migration sessions.
    await _storage.remove(StorageKeys.accessToken);
    await _storage.remove(StorageKeys.refreshToken);
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
    final url = ApiPaths.url(ApiPaths.authRefresh);

    // Diagnostic only — the actual Cookie header is no longer built by hand
    // here. `_dio` (the app's single, shared Dio — see the class doc) has a
    // CookieManager attached in ApiClient, which captures Set-Cookie on
    // every response (login included) and re-attaches matching cookies on
    // every request automatically, exactly mirroring the web clients'
    // `credentials: 'include'`. Peeking at the jar just tells us up front
    // whether this call has anything to send, so a truly session-less cold
    // start doesn't burn a network round-trip it can't win.
    final hasCookie = await _hasRefreshCookie(url);
    if (!hasCookie) {
      AppLogger.d('[TokenRefresh] no refresh-token cookie in jar for $url');
      return null;
    }

    final response = await _dio.post<dynamic>(
      url,
      // Empty body — the cookie (attached automatically by CookieManager)
      // is the credential, exactly as on web.
      data: const <String, dynamic>{},
      options: Options(
        headers: <String, String>{
          // Content-Type + accept only. Notably NO x-sub-channel: its presence
          // is what opts the request into the gateway's strict header matrix
          // (see AuthInterceptor's exemption), and a PARTIAL strict set is 4xx'd.
          ...ApiHeaders.json,
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

    await saveAccessToken(newAccess);

    // Invariant 4 — a rotated refresh token must survive. The jar
    // (CookieManager, attached in ApiClient) already captured any rotated
    // `Set-Cookie` automatically and will send it on the next refresh —
    // nothing here builds a Cookie header by hand anymore. Some backends
    // ALSO echo the rotated value in the JSON body; mirror that into the
    // legacy Keychain store too, purely for backward-compatible diagnostics.
    final rotated =
        (body['refreshToken'] ?? body['refresh_token'] ?? '').toString().trim();
    final rotatedCookie = _refreshTokenFromSetCookie(response.headers);
    final newRefresh = rotated.isNotEmpty ? rotated : rotatedCookie;
    if (newRefresh.isNotEmpty) {
      AppLogger.d('[TokenRefresh] refresh token rotated — mirroring to Keychain');
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

  /// Peeks the shared cookie jar for a refresh-token-shaped cookie scoped to
  /// [url], without making a request. Purely a fast-fail: skips a network
  /// round-trip that a session-less cold start can't win anyway. On any read
  /// failure this fails OPEN (returns true) — a jar glitch must not silently
  /// block every refresh forever; the actual POST is the real source of truth.
  Future<bool> _hasRefreshCookie(String url) async {
    try {
      final jar = serviceLocator<CookieJar>();
      final cookies = await jar.loadForRequest(Uri.parse(url));
      return cookies.any((c) => c.name.toLowerCase().contains('refresh'));
    } catch (e) {
      AppLogger.d('[TokenRefresh] cookie jar peek failed: $e');
      return true;
    }
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
    final accessToken = await readAccessToken();
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
    if (AppTime.nowUtc().add(skew).isBefore(expiresAt)) return true;

    AppLogger.d('[TokenRefresh] token expired/expiring — refreshing on resume');
    return (await refreshSession()) != null;
  }

  /// Extracts a `refreshToken` from a response's `Set-Cookie` headers, or ''
  /// when absent. Values are URL-decoded to mirror how they were sent. A
  /// browser would absorb this automatically; on mobile we have to. Public
  /// because [AuthRemoteDataSourceImpl.login] needs the identical fallback:
  /// the backend may deliver the refresh token via `Set-Cookie` there too,
  /// the same as it does on `/auth/refresh`.
  static String refreshTokenFromSetCookie(Headers headers) =>
      _refreshTokenFromSetCookie(headers);

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
