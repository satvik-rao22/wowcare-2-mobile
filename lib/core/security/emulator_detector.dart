import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class EmulatorDetector {
  static final _deviceInfo = DeviceInfoPlugin();

  /// Detects if the app is running on an emulator/simulator
  static Future<bool> isRunningOnEmulator() async {
    try {
      // Android detection
      if (await _isAndroidEmulator()) {
        return true;
      }

      // iOS detection
      if (await _isIosSimulator()) {
        return true;
      }

      return false;
    } catch (_) {
      // If we can't determine, assume it's not an emulator
      return false;
    }
  }

  /// Android-specific emulator detection
  static Future<bool> _isAndroidEmulator() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      // Property-based detection
      return !androidInfo.isPhysicalDevice ||
          androidInfo.manufacturer.toLowerCase().contains('unknown') ||
          androidInfo.model.toLowerCase().contains('sdk') ||
          androidInfo.model.toLowerCase().contains('emulator') ||
          androidInfo.brand.toLowerCase().contains('generic');
    } catch (_) {
      return false;
    }
  }

  /// iOS-specific simulator detection
  static Future<bool> _isIosSimulator() async {
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      return !iosInfo.isPhysicalDevice;
    } catch (_) {
      return false;
    }
  }

  /// Detects if this is a development build
  static Future<bool> isDevelopmentBuild() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      // Development builds typically have buildNumber '1'
      return packageInfo.buildNumber == '1';
    } catch (_) {
      return false;
    }
  }
}
