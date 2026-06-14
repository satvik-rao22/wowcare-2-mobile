import 'dart:io';

class DeviceIntegrityChecker {
  /// Detects if Android device is rooted
  static Future<bool> isRooted() async {
    if (!Platform.isAndroid) return false;

    // Common root files/directories on Android rooted devices
    final suspiciousFiles = [
      // Superuser/SuperSU
      '/system/bin/su',
      '/system/xbin/su',
      '/system/sbin/su',
      '/data/local/su',
      '/su/bin/su',
      // Apps
      '/system/app/Superuser.apk',
      '/system/app/SuperSU',
      '/system/app/SuperUser.apk',
      // Magisk
      '/data/adb/magisk',
      '/data/adb/magisk.db',
      '/cache/magisk.log',
      // Xposed Framework
      '/system/framework/XposedBridge.jar',
      '/system/lib/libxposed_art.so',
      // KernelSU
      '/data/adb/ksu',
    ];

    for (final file in suspiciousFiles) {
      try {
        if (await File(file).exists()) {
          return true;
        }
      } catch (_) {
        // Ignore permission errors
      }
    }

    return false;
  }

  /// Detects if iOS device is jailbroken
  static Future<bool> isJailbroken() async {
    if (!Platform.isIOS) return false;

    // Common jailbreak indicators on iOS
    final suspiciousFiles = [
      // Cydia
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      // Common jailbreak utilities
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/usr/bin/ssh',
      // Unc0ver
      '/Library/Caches/com.unc0ver.jailbreak',
      // Checkra1n
      '/usr/lib/libcheckra1n.dylib',
      // Sileo (modern package manager)
      '/Applications/Sileo.app',
    ];

    for (final file in suspiciousFiles) {
      try {
        if (await File(file).exists()) {
          return true;
        }
      } catch (_) {
        // Ignore permission errors
      }
    }

    return false;
  }

  /// Comprehensive integrity check
  /// Returns true if device is compromised (rooted/jailbroken)
  static Future<bool> isDeviceCompromised() async {
    if (await isRooted()) return true;
    if (await isJailbroken()) return true;
    return false;
  }
}
