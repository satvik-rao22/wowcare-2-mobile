// ignore_for_file: type=lint
// Generated from Firebase project: wowcare2-atoconn (PROD)
// TODO: Replace with the dedicated PRODUCTION Firebase project — do NOT share
//       API keys between UAT and PROD in a live app.
//       Run: flutterfire configure --project=<prod-project-id> --out=lib/core/firebase/firebase_options_prod.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class FirebaseOptionsProd {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOptionsProd is not configured for ${defaultTargetPlatform.name}',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCg5Q5-WMDmnO0paQNbBb3_Lys_SOASU30',
    appId: '1:767932730187:android:0ceececd6f0103241cf6ce',
    messagingSenderId: '767932730187',
    projectId: 'wowcare2-prod',
    storageBucket: 'wowcare2-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA15iigpnFAe6Zo85QK3baWKhXnB4rUXII',
    appId: '1:767932730187:ios:1f3b958333d932811cf6ce',
    messagingSenderId: '767932730187',
    projectId: 'wowcare2-prod',
    storageBucket: 'wowcare2-prod.firebasestorage.app',
    iosBundleId: 'com.wiseowl.wowcareapp',
  );
}
