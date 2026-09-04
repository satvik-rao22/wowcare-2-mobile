// ignore_for_file: type=lint
// DEV app environment uses the `wowcare1-dev` Firebase project — the one whose
// FCM sender matches the DEV backend at http://5.78.83.44, so pushes fired by
// that backend actually reach this build.
// To regenerate: flutterfire configure --project=wowcare1-dev --out=lib/core/firebase/firebase_options_dev.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class FirebaseOptionsDev {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOptionsDev is not configured for ${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB3N_mPQdhAAWQ3OG2NtWCy13EoPHAZkJQ',
    appId: '1:431943400820:android:35f02634eb17e4bb678021',
    messagingSenderId: '431943400820',
    projectId: 'wowcare1-dev',
    storageBucket: 'wowcare1-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBqp410XnTTesBEnB5JIKaKnkIUzhOPBIA',
    appId: '1:431943400820:ios:590643a95472e35f678021',
    messagingSenderId: '431943400820',
    projectId: 'wowcare1-dev',
    storageBucket: 'wowcare1-dev.firebasestorage.app',
    iosBundleId: 'com.wiseowl.wowcareapp',
  );
}
