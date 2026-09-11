import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wowcare/core/auth/token_refresh_service.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

/// Mirrors the web's `firebaseAuth.ts` — exchanges the Keycloak JWT for a
/// Firebase Custom Token via the messaging-service backend, then signs the
/// Flutter app into Firebase Auth with [signInWithCustomToken].
///
/// Firestore security rules use `request.auth.uid == userCode`, so every
/// Firestore listener (inbox, messages) will return `permission-denied` until
/// this sign-in succeeds. REST APIs and push notifications are unaffected.
///
/// Call [signIn] after WowCare login completes. Call [signOut] on logout.
class FirebaseAuthService {
  FirebaseAuthService({required Dio dio, required StorageService storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final StorageService _storage;

  // Dedup concurrent sign-in calls — multiple listeners (inbox + message thread)
  // mount simultaneously on first open. Once sign-in succeeds the completed
  // Future is retained so subsequent calls return immediately.
  Future<void>? _inFlight;

  /// Exchange the current Keycloak token for a Firebase Custom Token and sign in.
  ///
  /// The AuthInterceptor on the shared Dio instance automatically injects the
  /// current (auto-refreshed) Bearer token and the X-Organization-Code /
  /// X-School-Code headers — no parameters are needed here.
  ///
  /// Non-fatal: failures are logged but never rethrown. Firestore listeners
  /// will get permission-denied errors (as before) while the rest of the app
  /// (Keycloak auth, REST APIs) continues to work normally.
  Future<void> signIn() async {
    // No WowCare session yet → there is no Keycloak JWT to exchange, so
    // `/firebase/token` can only 401. That 401 is NOT a session expiry, but it
    // rides the shared Dio and therefore reaches [SessionExpiredInterceptor],
    // which (finding no refresh token either) runs the full logout cascade:
    // red "Your session has expired" snackbar + a forced go(sign-in). On a
    // FRESH INSTALL that fires from `_TokenLifecycleObserver._refreshAll()` on
    // the first `resumed` lifecycle event — i.e. while the user is still on the
    // onboarding pages — so they land on Login with an expiry error for a
    // session that never existed. Bail out before the request instead.
    final accessToken = await TokenRefreshService.instance.readAccessToken();
    if (accessToken.isEmpty) {
      AppLogger.d('[FirebaseAuth] No app session yet — skipping sign-in');
      return;
    }
    // Ensure the Firebase session matches the CURRENT app user. signIn() is called
    // on every auth change (login, session restore, org/school/persona switch), so
    // it MUST be able to re-authenticate — not permanently no-op.
    //
    // The Firebase uid is the userCode (Firestore rules: request.auth.uid == userCode).
    // The old code kept `_inFlight` as a *completed* future forever, so every call
    // after the first returned immediately: after switching accounts, Firebase stayed
    // signed in as the previous user and the new user's Firestore listeners all got
    // permission-denied — no unread counts, no live list, no live thread. This is the
    // recurring "live sync stopped again" failure.
    final targetUser =
        (await _storage.getString(StorageKeys.userCode) ?? '').trim();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (targetUser.isNotEmpty && currentUid == targetUser) {
      return; // already signed into Firebase as the current user — nothing to do
    }
    // Dedup only genuinely-concurrent calls (multiple listeners open at once).
    if (_inFlight != null) return _inFlight;
    _inFlight = _doSignIn();
    return _inFlight;
  }

  Future<void> _doSignIn() async {
    try {
      final customToken = await _fetchCustomToken();
      if (customToken == null || customToken.isEmpty) {
        AppLogger.w('[FirebaseAuth] Custom token missing in response — skipping sign-in');
        return;
      }
      // signInWithCustomToken replaces any existing session, so this correctly
      // switches Firebase to the current user when the account changed.
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      AppLogger.d('[FirebaseAuth] Signed in to Firebase successfully');
    } catch (e) {
      AppLogger.e('[FirebaseAuth] Failed to sign in to Firebase: $e');
    } finally {
      // Always clear so a later signIn() (next auth change / retry) can re-attempt,
      // instead of being blocked forever by a retained completed future.
      _inFlight = null;
    }
  }

  /// Sign out of Firebase Auth. Call on WowCare logout so Firestore listeners
  /// immediately lose read permission.
  Future<void> signOut() async {
    _inFlight = null;
    try {
      await FirebaseAuth.instance.signOut();
      AppLogger.d('[FirebaseAuth] Signed out of Firebase');
    } catch (e) {
      AppLogger.w('[FirebaseAuth] Failed to sign out of Firebase: $e');
    }
  }

  /// Whether the app currently has an active Firebase Auth session.
  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<String?> _fetchCustomToken() async {
    final endpoint = ApiPaths.urlWithBase(
      '/api/v1/firebase/token',
      ApiConstants.communicationBaseUrl,
    );

    // No explicit Authorization or org/school headers — the AuthInterceptor
    // on _dio automatically injects the current (auto-refreshed) Bearer token
    // from storage plus X-Organization-Code and X-School-Code. Passing them
    // manually here would lock in the potentially-expired cached access token
    // because AuthInterceptor skips auth injection when Authorization is already set.
    final response = await _dio.post<Map<String, dynamic>>(endpoint);

    final body = response.data ?? {};
    final dataWrapper = body['data'] as Map<String, dynamic>?;
    return (dataWrapper?['customToken'] ?? body['customToken']) as String?;
  }
}
