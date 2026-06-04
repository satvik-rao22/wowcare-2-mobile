# Production Hardening Guide - WowCare Flutter App

## 1. ROOT CAUSE ANALYSIS

### Issue 1: Firebase/Firestore Version Conflict

**Root Cause:**
- Your pubspec.yaml specifies different Firebase package versions
- Firebase Core: 4.1.0
- Cloud Firestore: 6.0.1
- Each package has its own native iOS pod dependencies
- Cocoapods tries to resolve conflicting Firebase pod versions
- Error occurs when one pod requires Firebase/Firestore = 12.9.0 but another requires 12.13.0

**Why It Happens:**
1. Different Firebase packages have different pod version constraints
2. Podfile.lock caches old version constraints
3. iOS build tries to resolve transitive dependencies
4. Version mismatch occurs between plugin expectations

**Solution:**
- Update firebase_core to latest compatible version
- Update all Firebase packages together
- Force specific Firebase pod version in Podfile
- Clean Podfile.lock and regenerate

---

### Issue 2: arm64 Simulator on Apple Silicon

**Root Cause:**
- `ffmpeg_kit_flutter_new_https` plugin is compiled for arm64-v8a (physical device architecture)
- Apple Silicon Macs use arm64 for simulator
- Plugin binary doesn't support arm64 simulator target
- Build fails because architecture mismatch

**Why It Happens:**
1. ffmpeg_kit is native iOS/Android library
2. Some architectures aren't built for simulator targets
3. Xcode can't find compiled binary for arm64 simulator arch

**Solution:**
- Exclude arm64 from iOS simulator builds
- Use x86_64 for Intel Mac simulators
- Use arm64 for physical devices only
- Add platform-specific build configuration in Podfile

---

## 2. CURRENT ISSUES SUMMARY

| Issue | Impact | Fix |
|-------|--------|-----|
| Firebase pod mismatch | iOS build fails | Update pods to compatible versions |
| arm64 simulator unsupported | Can't test on Apple Silicon simulator | Exclude arm64 from simulator builds |
| Missing release config | APK/IPA not optimized | Add proper release signing & obfuscation |
| No obfuscation | Code reversible | Enable --obfuscate in builds |
| Debug info in release | Binary bloated | Split debug info |

---

## 3. IMMEDIATE FIXES REQUIRED

### A. Update pubspec.yaml Firebase Packages

```yaml
# Update these to compatible versions
firebase_core: ^5.0.0        # Latest stable
firebase_messaging: ^16.0.1  # Compatible
cloud_firestore: ^7.0.0      # Requires firebase_core ^5.0.0
firebase_storage: ^13.0.1    # Compatible
```

### B. Update ffmpeg_kit_flutter_new_https

The `ffmpeg_kit_flutter_new_https ^2.1.0` has known arm64 simulator issues.

**Options:**
1. **Keep and configure** - Exclude arm64 from simulator (RECOMMENDED)
2. **Replace** - Use alternative like `just_audio` or `video_player` if possible
3. **Update** - Check for newer versions

---

## 4. SECURITY REQUIREMENTS IMPLEMENTATION

### A. Emulator Detection

Add to `lib/core/security/emulator_detector.dart`:

```dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class EmulatorDetector {
  static Future<bool> isRunningOnEmulator() async {
    final deviceInfo = DeviceInfoPlugin();
    
    // Android detection
    try {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.isPhysicalDevice == false;
    } catch (_) {}
    
    // iOS detection
    try {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.isPhysicalDevice == false;
    } catch (_) {}
    
    return false;
  }

  static Future<bool> isDevelopmentBuild() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber == '1'; // Debug build indicator
  }
}
```

### B. Root/Jailbreak Detection

Add to `lib/core/security/device_integrity_checker.dart`:

```dart
import 'dart:io';

class DeviceIntegrityChecker {
  static Future<bool> isRooted() async {
    if (!Platform.isAndroid) return false;
    
    // Common root files/directories on Android
    final suspiciousFiles = [
      '/system/bin/su',
      '/system/xbin/su',
      '/system/sbin/su',
      '/data/local/su',
      '/su/bin/su',
      '/system/app/Superuser.apk',
      '/system/app/SuperSU',
      '/system/app/SuperUser.apk',
      '/data/adb/magisk',
    ];
    
    for (final file in suspiciousFiles) {
      if (await File(file).exists()) {
        return true;
      }
    }
    
    return false;
  }

  static Future<bool> isJailbroken() async {
    if (!Platform.isIOS) return false;
    
    final suspiciousFiles = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
    ];
    
    for (final file in suspiciousFiles) {
      if (await File(file).exists()) {
        return true;
      }
    }
    
    return false;
  }
}
```

### C. Disable Screenshots on Sensitive Screens

In `lib/core/security/screenshot_protection.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScreenshotProtection {
  static const _channel = MethodChannel('com.wiseowl.wowcareapp/security');

  static Future<void> preventScreenshots() async {
    try {
      await _channel.invokeMethod('preventScreenshots');
    } catch (e) {
      print('Error preventing screenshots: $e');
    }
  }

  static Future<void> allowScreenshots() async {
    try {
      await _channel.invokeMethod('allowScreenshots');
    } catch (e) {
      print('Error allowing screenshots: $e');
    }
  }
}
```

Add to `android/app/src/main/kotlin/com/wiseowl/wowcareapp/MainActivity.kt`:

```kotlin
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.wiseowl.wowcareapp/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "preventScreenshots" -> {
                        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, 
                            WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "allowScreenshots" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

### D. Disable Debug Logs in Release

Add to `lib/main.dart`:

```dart
void main() {
  // Disable logs in release mode
  if (kReleaseMode) {
    // Disable print logging
    debugPrint = (String? message, {int? wrapWidth}) {};
    
    // Disable Firebase debug logging
    FirebaseCore.instance.debugLogging = false;
  }
  
  runApp(const MyApp());
}
```

### E. Firebase App Check Integration

Add to `lib/core/security/firebase_app_check.dart`:

```dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseAppCheckSetup {
  static Future<void> initialize() async {
    await FirebaseAppCheck.instance.activate(
      // Android configuration
      androidProvider: AndroidProvider.playIntegrity,
      // iOS configuration
      appleProvider: AppleProvider.appAttest,
    );
  }
}
```

Update `pubspec.yaml`:

```yaml
dependencies:
  firebase_app_check: ^0.3.0
```

### F. SSL Pinning

Add to `lib/core/network/http_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class PinnedHttpClient {
  static Future<Dio> createPinnedClient() async {
    final dio = Dio();
    
    // Load certificate from assets
    final certificate = await rootBundle.load('assets/certs/api_cert.pem');
    
    // Configure pinning
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      SecurityContext context = SecurityContext.defaultContext;
      context.setClientAuthoritiesBytes(certificate.buffer.asUint8List());
      return client;
    };
    
    return dio;
  }
}
```

### G. Secure API Configuration

Update `lib/core/network/api_client.dart`:

```dart
class ApiClient {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.wowcare.app', // Production default
  );

  static const Duration timeout = Duration(seconds: 30);
  
  // Enable SSL pinning
  static const bool enableSSLPinning = true;
  
  // Disable HTTP (force HTTPS only)
  static const bool forceHttps = true;
}
```

---

## 5. BUILD SIZE OPTIMIZATION

### Remove Unused Dependencies

Check for unused packages and remove:
```bash
flutter pub deps --tree | grep "..."
```

### Configure ProGuard/R8 Rules

Create `android/app/proguard-rules.pro`:

```pro
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# Dart/Flutter
-keep class com.google.dart.** { *; }
-keep interface com.google.dart.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Keep app models
-keep class com.wiseowl.wowcareapp.models.** { *; }
-keep class com.wiseowl.wowcareapp.entities.** { *; }
```

### Enable Kotlin Minification

Already done in `build.gradle.kts` with:
```kotlin
isMinifyEnabled = true
isShrinkResources = true
```

---

## 6. NEXT STEPS

1. ✅ Update Podfile (see iOS Release Setup section)
2. ✅ Update build.gradle.kts (see Android Release Setup section)
3. ✅ Create build scripts (see Build Automation section)
4. ✅ Add security implementations
5. Run: `flutter clean && flutter pub get`
6. Test on real devices before release
7. Use release build script: `./scripts/build_ios_release.sh`

