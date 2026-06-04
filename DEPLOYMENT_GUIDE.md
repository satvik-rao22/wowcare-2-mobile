# Production Deployment Guide - WowCare Flutter App

This guide walks through deploying the comprehensive production hardening changes to the WowCare app.

## Prerequisites

- Flutter 3.9.2+
- Android NDK 28.2.13676358
- Xcode 15+ (iOS)
- CocoaPods (iOS)
- Java 11+
- Release signing credentials for Android (keystore)
- Apple Developer Account (iOS)

---

## Phase 1: Dependency Updates

### Step 1.1: Update Firebase Packages in pubspec.yaml

Update your Firebase dependencies to compatible versions:

```yaml
firebase_core: ^5.0.0        # Updated from 4.1.0
firebase_messaging: ^16.0.1  # Compatible with firebase_core ^5.0.0
cloud_firestore: ^7.0.0      # Updated from 6.0.1, requires firebase_core ^5.0.0
firebase_storage: ^13.0.1    # Compatible
firebase_app_check: ^0.3.0   # NEW: For app authenticity verification
```

**Why:** Resolves pod version conflicts on iOS and ensures feature compatibility.

### Step 1.2: Get Updated Dependencies

```bash
flutter clean
flutter pub get --no-precompile
```

---

## Phase 2: Android Release Configuration

### Step 2.1: Deploy Build Configuration

Replace the current `android/app/build.gradle.kts` with the production version:

```bash
# Backup current configuration
cp android/app/build.gradle.kts android/app/build.gradle.kts.backup

# Deploy production configuration
cp android/app/build.gradle.kts.production android/app/build.gradle.kts
```

**What changed:**
- `isMinifyEnabled = true` for code obfuscation
- `isShrinkResources = true` for resource optimization
- Release signing configuration (reads from `local.properties`)
- ProGuard/R8 configuration applied
- Bundle configuration for Google Play split APKs

### Step 2.2: Deploy ProGuard Rules

The file `android/app/proguard-rules-production.pro` has been created. Ensure it's referenced in `build.gradle.kts`:

```kotlin
proguardFiles(
    getDefaultProguardFile("proguard-android-optimize.txt"),
    flutterProguardRules,
    appProguard,  // This references proguard-rules.pro
)
```

If you have custom ProGuard rules, merge them with `proguard-rules-production.pro`.

### Step 2.3: Configure Release Signing

Create/update `android/local.properties`:

```properties
flutter.sdk=/path/to/flutter
flutter.buildMode=release
flutter.targetPlatform=android-arm64

# Release signing configuration
RELEASE_KEYSTORE_PATH=/path/to/your/keystore.jks
RELEASE_KEYSTORE_PASSWORD=your_keystore_password
RELEASE_KEY_ALIAS=your_key_alias
RELEASE_KEY_PASSWORD=your_key_password
```

**To generate a keystore:**

```bash
keytool -genkey -v \
  -keystore app-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias app_key \
  -dname "CN=Company Name, O=Organization, C=Country"
```

---

## Phase 3: iOS Release Configuration

### Step 3.1: Deploy iOS Podfile

Replace the current `ios/Podfile` with the production version:

```bash
# Backup current Podfile
cp ios/Podfile ios/Podfile.backup

# Deploy production Podfile
cp ios/Podfile.production ios/Podfile
```

**What changed:**
- Firebase pod version pinning to 12.13.0
- arm64 simulator exclusion (for ffmpeg_kit compatibility)
- Production optimization flags
- CocoaPods stats disabled for faster builds

### Step 3.2: Regenerate CocoaPods

```bash
cd ios
rm Podfile.lock
rm -rf Pods/

COCOAPODS_DISABLE_STATS=true pod install --repo-update
cd ..
```

**Wait:** This may take 3-5 minutes. It's downloading optimized pods for production.

### Step 3.3: Verify iOS Build

```bash
flutter build ios --release --config-only
# If no errors, proceed to next phase
```

---

## Phase 4: Security Implementation

### Step 4.1: Android Security - Method Channel

The `android/app/src/main/kotlin/com/wiseowl/wowcareapp/security/SecurityMethodChannel.kt` has been created with screenshot prevention support.

The `MainActivity.kt` has been updated to initialize this channel.

**Verify:** Check that the import is present:
```kotlin
import com.wiseowl.wowcareapp.security.SecurityMethodChannel
```

### Step 4.2: Dart Security Classes

The following files have been created in `lib/core/security/`:

- **emulator_detector.dart** - Detects if running on emulator/simulator
- **device_integrity_checker.dart** - Detects rooted/jailbroken devices
- **screenshot_protection.dart** - Prevents screenshots on sensitive screens
- **firebase_app_check.dart** - (Stub) Firebase App Check setup

### Step 4.3: Integrate Security Checks in Your App

Add security initialization to `lib/main.dart`:

```dart
import 'package:wowcare/core/security/emulator_detector.dart';
import 'package:wowcare/core/security/device_integrity_checker.dart';
import 'package:wowcare/core/security/screenshot_protection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check for compromised devices in production
  if (kReleaseMode) {
    final isEmulator = await EmulatorDetector.isRunningOnEmulator();
    final isCompromised = await DeviceIntegrityChecker.isDeviceCompromised();

    if (isEmulator || isCompromised) {
      // Handle compromise: show warning, disable features, or exit
      print('Device security check failed');
    }
  }

  runApp(const MyApp());
}
```

### Step 4.4: Apply Screenshot Protection

On sensitive screens (login, payment, etc.):

```dart
@override
void initState() {
  super.initState();
  // Prevent screenshots on this sensitive screen
  ScreenshotProtection.preventScreenshots();
}

@override
void dispose() {
  // Re-enable screenshots when leaving
  ScreenshotProtection.allowScreenshots();
  super.dispose();
}
```

---

## Phase 5: Build Automation

### Step 5.1: Make Build Scripts Executable

```bash
chmod +x scripts/build_android_release.sh
chmod +x scripts/build_ios_release.sh
```

### Step 5.2: Android Release Build

```bash
./scripts/build_android_release.sh
```

**Output:**
- `releases/app-release-YYYYMMDD_HHMMSS.aab` (for Google Play)
- `releases/app-release-YYYYMMDD_HHMMSS.apk` (for testing)
- `releases/debug-symbols/YYYYMMDD_HHMMSS/` (for crash reporting)

### Step 5.3: iOS Release Build

```bash
./scripts/build_ios_release.sh
```

**Output:**
- `releases/app-release-YYYYMMDD_HHMMSS.ipa` (for App Store/TestFlight)
- `releases/debug-symbols/YYYYMMDD_HHMMSS/` (for crash reporting)

---

## Phase 6: Testing

### Step 6.1: Test Android Release APK

```bash
# List connected devices
adb devices

# Install release APK
adb install releases/app-release-*.apk

# Run app and check:
# - No debug logs appear
# - Security checks work
# - All features function normally
```

### Step 6.2: Test iOS Release IPA

```bash
# Using Xcode Organizer (recommended)
# Or Transporter for automated testing

# Manual testing:
# - Install on real device
# - Check no debug logs
# - Verify security features
# - Test all critical flows
```

### Step 6.3: Verify Obfuscation

For Android:
```bash
# Decompile APK to verify obfuscation
unzip releases/app-release-*.apk -d apk_contents
cd apk_contents
dex2jar classes.dex
# Open with JD-GUI to verify classes are obfuscated
```

For iOS:
```bash
# Debug symbols are stored separately for security
# The IPA contains obfuscated code but is readable via symbols
ls -la releases/debug-symbols/*/
```

---

## Phase 7: Deployment

### Android Deployment

```bash
# Using bundletool to test the AAB
bundletool build-apks \
  --bundle=releases/app-release-*.aab \
  --output=releases/app.apks \
  --mode=universal

# Install universal APK for testing
bundletool install-apks --apks=releases/app.apks

# Upload AAB to Google Play Console
# Play Console > Select App > Release > Create New Release > Upload AAB
```

### iOS Deployment

```bash
# Option 1: Using Xcode
open releases/app-release-*.ipa

# Option 2: Using Transporter
open -a Transporter releases/app-release-*.ipa

# In App Store Connect:
# - Select TestFlight > iOS Builds
# - Upload IPA via Transporter
# - Wait for processing and submission review
```

---

## Phase 8: Firebase App Check Setup (Optional but Recommended)

If you added `firebase_app_check` to pubspec.yaml:

### Android Setup
1. Go to Firebase Console > App Check
2. Click "Register app"
3. Select Android app
4. Use "Play Integrity" provider
5. Verify Play Store listing requirements

### iOS Setup
1. Go to Firebase Console > App Check
2. Click "Register app"
3. Select iOS app
4. Use "App Attest" provider
5. Wait for Apple's verification (24-48 hours)

### Enable Enforcement
```javascript
// In Cloud Firestore Security Rules:
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Require valid App Check token
    match /{document=**} {
      allow read, write: if request.auth != null 
        && request.headers.get('x-firebase-app-check') != null;
    }
  }
}
```

---

## Troubleshooting

### Issue: iOS Build Fails with Firebase Pod Errors

```bash
# Solution: Clean and reinstall pods
cd ios
rm -rf Pods/ Podfile.lock .symlinks/
pod install --repo-update
cd ..
```

### Issue: Android Build Fails with ProGuard Errors

```bash
# Check for missing keep rules
grep -r "Warning: can't find referenced class" build/

# Add missing rules to proguard-rules-production.pro:
-keep class your.missing.Class { *; }

# Rebuild
flutter build appbundle --release
```

### Issue: Obfuscated Code Causes Runtime Errors

1. Add class to ProGuard keep rules:
   ```pro
   -keep class com.wiseowl.wowcareapp.YourClass { *; }
   ```

2. Rebuild with `-v` for verbose output:
   ```bash
   flutter build apk --release -v
   ```

3. Check Proguard mapping:
   ```
   build/app/intermediates/mapping/release/mapping.txt
   ```

---

## Post-Deployment Checklist

- [ ] Android AAB uploaded to Google Play
- [ ] iOS IPA uploaded to TestFlight
- [ ] Security checks active in release builds
- [ ] Obfuscation verified (code is not readable)
- [ ] Debug symbols stored securely
- [ ] Firebase App Check enabled (optional)
- [ ] Crash reporting configured
- [ ] Analytics enabled
- [ ] No sensitive data in logs (disabled in release)
- [ ] Team notified of new release

---

## Monitoring & Maintenance

### Weekly
- Monitor crash reports
- Check for any user-reported security issues
- Review logs from device integrity checks

### Monthly
- Update Firebase packages
- Review ProGuard rules for new dependencies
- Update security signatures

### Quarterly
- Penetration test on real devices
- Security audit of API calls
- Review device integrity statistics

---

## Additional Resources

- [Flutter Security Best Practices](https://flutter.dev/docs/testing/security)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)
- [Firebase App Check](https://firebase.google.com/docs/app-check)
- [ProGuard Documentation](https://www.guardsquare.com/proguard/manual)

---

## Support

For issues during deployment:
1. Check troubleshooting section above
2. Review build logs with `-v` flag
3. Consult relevant platform documentation
4. Contact your team lead or DevOps team

