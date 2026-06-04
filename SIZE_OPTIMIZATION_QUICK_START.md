# App Size Optimization - Quick Start Guide

## TL;DR (5 Minutes)

The app is 223 MB. Fix it now:

### Step 1: Fix ABI Filtering (2 min)

Edit `android/app/build.gradle.kts` line 56-78. Replace buildTypes.release section with:

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
        isMinifyEnabled = true
        isShrinkResources = true
        
        // ✅ ADD THIS: Exclude emulator-only architecture
        ndk {
            abiFilters.clear()
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }

        val appProguard = layout.projectDirectory.file("proguard-rules.pro").asFile
        if (appProguard.exists()) {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                flutterProguardRules,
                appProguard,
            )
        } else {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                flutterProguardRules,
            )
        }
    }
}
```

**Saves: -65 MB**

### Step 2: Build with Optimization Flags (1 min)

```bash
flutter clean
flutter pub get

flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info=build/app/profiles \
    --tree-shake-icons
```

**Saves: -3 MB**

### Step 3: Verify

```bash
ls -lh build/app/outputs/apk/release/app-release.apk
# Should show ~150-160 MB instead of 223 MB
```

---

## That's It! You're Done with Priority 1

**Before:** 223 MB  
**After:** ~160 MB  
**Savings:** 63 MB (-28%)

---

## Want More Savings? (Optional)

### Option A: Replace FFmpeg (Saves -25 MB more)

If you're **only playing videos**, not encoding them:

**In `pubspec.yaml`, find and remove:**
```yaml
ffmpeg_kit_flutter_new_https: ^2.1.0
```

**Then:**
```bash
flutter pub get
flutter clean
flutter build apk --release --obfuscate --split-debug-info=build/app/profiles --tree-shake-icons
```

**Final Size:** ~135 MB

---

### Option B: Optimize Images (Saves -5-10 MB)

Convert PNG to WebP:
```bash
# Install webp tools
brew install webp  # macOS
# or: sudo apt install webp  (Linux)

# Convert images
find assets/ -name "*.png" -type f ! -name "*.9.png" | while read f; do
    cwebp -q 85 "$f" -o "${f%.png}.webp"
done
```

Remove original PNG files after verifying WebP versions work.

**Savings: -5 to -10 MB**  
**Final Size:** ~125 MB

---

## Size Reduction Summary

| Action | Savings | Effort | Risk |
|--------|---------|--------|------|
| Fix ABI filtering (Priority 1) | -65 MB | 2 min | None |
| Optimization flags (Priority 1) | -3 MB | 1 min | None |
| Replace FFmpeg (Priority 2) | -25 MB | 5 min | Medium |
| Optimize images (Priority 2) | -8 MB | 10 min | Low |
| **Total Possible** | **-101 MB** | **18 min** | **Low** |

**Minimum (Just Priority 1): ~160 MB**  
**Recommended (Priority 1+2): ~120 MB**  
**Maximum (All steps): ~110-120 MB**

---

## Detailed Implementation

See detailed guides:
- `APP_SIZE_OPTIMIZATION_AUDIT.md` - Full analysis & root causes
- `APP_SIZE_OPTIMIZATION_IMPLEMENTATION.md` - Step-by-step implementation
- `APP_SIZE_OPTIMIZATION_CHECKLIST.md` - Testing & verification (create this)

---

## Testing

```bash
# After making changes, test thoroughly:

# 1. Build
flutter clean
flutter pub get
flutter build apk --release --obfuscate --split-debug-info=build/app/profiles --tree-shake-icons

# 2. Install on device
adb install build/app/outputs/apk/release/app-release.apk

# 3. Test all features
# - Open app
# - Navigate all screens
# - Test video playback
# - Test PDF viewing (if used)
# - Test QR scanning
# - Test API calls
# - Check no crashes
```

---

## FAQ

**Q: Will this break my app?**  
A: No, Priority 1 is safe. Priority 2 depends on features you use.

**Q: How much should the final APK be?**  
A: ~40-50 MB for APK, ~25-35 MB for AAB (what Google Play serves).

**Q: Should I use APK or AAB?**  
A: AAB for Google Play (smaller, serves per-architecture). APK for direct distribution.

**Q: What about iOS?**  
A: iOS optimization is separate. Similar principles apply. See APP_SIZE_OPTIMIZATION_AUDIT.md for iOS.

**Q: My app still crashes after optimizations?**  
A: Check if ProGuard removed important classes. Add to `android/app/proguard-rules.pro`:
```pro
-keep class com.your.CrashedClass { *; }
```
Then rebuild.

---

## Quick Reference

**Most Important File:** `android/app/build.gradle.kts`

**Most Important Build Command:**
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/profiles --tree-shake-icons
```

**Check APK Size:**
```bash
ls -lh build/app/outputs/apk/release/app-release.apk
```

**See Inside APK:**
```bash
cd /tmp
unzip build/app/outputs/apk/release/app-release.apk
du -sh lib/ assets/ classes*.dex
```

---

Done! Start with Step 1 above. 🚀

