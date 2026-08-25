import 'package:firebase_core/firebase_core.dart';
import 'package:wowcare/core/firebase/firebase_config_factory.dart';

/// Initializes Firebase idempotently.
///
/// Android auto-initializes the default `[DEFAULT]` app from
/// `google-services.json` (via `FirebaseInitProvider`) before `main()` runs.
/// The Dart-side `Firebase.apps` list is NOT synced with that native app until
/// after the first `initializeApp` call, so an `isEmpty` guard isn't enough —
/// calling `initializeApp(options:)` still throws `[core/duplicate-app]` when
/// the native app already exists with different options. We catch that and
/// reuse the existing default app instead of crashing.
Future<void> ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: FirebaseConfigFactory.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // Native already created [DEFAULT] from google-services.json — reuse it.
      return;
    }
    rethrow;
  }
}
