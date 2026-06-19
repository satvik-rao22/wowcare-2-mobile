// ignore_for_file: type=lint
// Generated from Firebase project: wowcare2-atoconn (UAT)
// To regenerate: flutterfire configure --project=wowcare2-atoconn --out=lib/core/firebase/firebase_options_uat.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class FirebaseOptionsUat {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOptionsUat is not configured for ${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAVcVF2dd1SSCpRD2-tqq-ACX-ILK5v0lk',
    appId: '1:103185714773:android:9ca80eef9f6c34f2ed4edc',
    messagingSenderId: '103185714773',
    projectId: 'wowcare2-uat',
    storageBucket: 'wowcare2-uat.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBYHqXcgPTcD1x5fLeLVDUbOsQ5QrA7Ee0',
    appId: '1:103185714773:ios:637e6e6638df5a65ed4edc',
    messagingSenderId: '103185714773',
    projectId: 'wowcare2-uat',
    storageBucket: 'wowcare2-uat.firebasestorage.app',
    iosBundleId: 'com.wiseowl.wowcareapp',
  );
}
