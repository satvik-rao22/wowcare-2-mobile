// ignore_for_file: type=lint
// Generated from Firebase project: wowcare2-atoconn (QA)
// TODO: Replace with a dedicated QA Firebase project when available.
//       Run: flutterfire configure --project=<qa-project-id> --out=lib/core/firebase/firebase_options_qa.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class FirebaseOptionsQa {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOptionsQa is not configured for ${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDkhMORPMLcJKiG76zYRGWRPGQqB5pNu1w',
    appId: '1:861387942693:android:2fbd1cd64e4171275548cc',
    messagingSenderId: '861387942693',
    projectId: 'wowcare2-atoconn',
    storageBucket: 'wowcare2-atoconn.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0F4lAWYniARnK39Z_PV8_PYmBmDQrvv4',
    appId: '1:861387942693:ios:6d658e9f7daf22295548cc',
    messagingSenderId: '861387942693',
    projectId: 'wowcare2-atoconn',
    storageBucket: 'wowcare2-atoconn.firebasestorage.app',
    iosBundleId: 'com.wiseowl.wowcareapp',
  );
}
