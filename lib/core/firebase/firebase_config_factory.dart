// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'firebase_options_local.dart';
import 'firebase_options_qa.dart';
import 'firebase_options_uat.dart';
import 'firebase_options_prod.dart';

// Compile-time constant injected by --dart-define=ENVIRONMENT=<value>.
// Defaults to UAT so a bare `flutter run` (without make) still works.
const _env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'UAT');

abstract final class FirebaseConfigFactory {
  /// Returns [FirebaseOptions] for the current build environment.
  ///
  /// Resolved at compile time from --dart-define=ENVIRONMENT=<LOCAL|QA|UAT|PROD>.
  static FirebaseOptions get currentPlatform {
    switch (_env.toUpperCase()) {
      case 'LOCAL':
        return FirebaseOptionsLocal.currentPlatform;
      case 'QA':
        return FirebaseOptionsQa.currentPlatform;
      case 'PROD':
        return FirebaseOptionsProd.currentPlatform;
      case 'UAT':
      default:
        return FirebaseOptionsUat.currentPlatform;
    }
  }

  static String get environmentName => _env.toUpperCase();
}
