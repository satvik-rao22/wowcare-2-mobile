import 'package:flutter/services.dart';
import '../util/logger_service.dart';

class ScreenshotProtection {
  static const _channel = MethodChannel('com.wiseowl.wowcareapp/security');

  /// Prevents screenshots on sensitive screens (e.g., authentication)
  static Future<void> preventScreenshots() async {
    try {
      await _channel.invokeMethod<void>('preventScreenshots');
    } catch (e) {
      AppLogger.e('Error preventing screenshots: $e');
    }
  }

  /// Re-enables screenshots after leaving sensitive screen
  static Future<void> allowScreenshots() async {
    try {
      await _channel.invokeMethod<void>('allowScreenshots');
    } catch (e) {
      AppLogger.e('Error allowing screenshots: $e');
    }
  }

  /// Checks if screenshots are currently prevented
  static Future<bool> isScreenshotPrevented() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isScreenshotPrevented');
      return result ?? false;
    } catch (e) {
      AppLogger.e('Error checking screenshot status: $e');
      return false;
    }
  }
}
