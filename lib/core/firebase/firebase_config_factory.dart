// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'firebase_options_dev.dart';
import 'firebase_options_local.dart';
import 'firebase_options_qa.dart';
import 'firebase_options_uat.dart';
import 'firebase_options_prod.dart';

// Compile-time constant injected by --dart-define=ENVIRONMENT=<value>.
// Defaults to DEV to match [ApiConstants], so a bare `flutter run` puts the
// backend and Firebase in the same environment instead of splitting them.
const _env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'DEV');

abstract final class FirebaseConfigFactory {
  /// Returns [FirebaseOptions] for the current build environment.
  ///
  /// Resolved at compile time from
  /// --dart-define=ENVIRONMENT=<DEV|LOCAL|QA|UAT|PROD>.
  ///
  /// Firebase must track the same environment as the REST backend: a push is
  /// only delivered when the sending project matches the one the app registered
  /// its FCM token against. DEV → `wowcare1-dev`, which is the project the DEV
  /// backend (http://5.78.83.44) sends from.
  static FirebaseOptions get currentPlatform {
    switch (_env.toUpperCase()) {
      case 'LOCAL':
        return FirebaseOptionsLocal.currentPlatform;
      case 'QA':
        return FirebaseOptionsQa.currentPlatform;
      case 'PROD':
        return FirebaseOptionsProd.currentPlatform;
      case 'UAT':
        return FirebaseOptionsUat.currentPlatform;
      case 'DEV':
      default:
        return FirebaseOptionsDev.currentPlatform;
    }
  }

  static String get environmentName => _env.toUpperCase();
}
