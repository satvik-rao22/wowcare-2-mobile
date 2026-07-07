import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/logger_service.dart';

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
  FirebaseAuthService({required Dio dio}) : _dio = dio;

  final Dio _dio;

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
    if (_inFlight != null) return _inFlight;
    _inFlight = _doSignIn();
    return _inFlight;
  }

  Future<void> _doSignIn() async {
    try {
      final customToken = await _fetchCustomToken();
      if (customToken == null || customToken.isEmpty) {
        AppLogger.w('[FirebaseAuth] Custom token missing in response — skipping sign-in');
        _inFlight = null;
        return;
      }
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      AppLogger.d('[FirebaseAuth] Signed in to Firebase successfully');
    } catch (e) {
      // Non-fatal — clear dedup so a subsequent call can retry.
      AppLogger.e('[FirebaseAuth] Failed to sign in to Firebase: $e');
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
