# App Size Optimization - Testing & Verification Checklist

## Pre-Optimization Baseline

- [ ] Record current APK size: **223 MB**
- [ ] Record current AAB size: **~150 MB** (estimated)
- [ ] Verify app works before optimization

---

## Phase 1: ABI Filtering Optimization

### Implementation
- [ ] Edit `android/app/build.gradle.kts`
- [ ] Add `ndk { abiFilters.clear(); abiFilters.addAll(...) }` to buildTypes.release
- [ ] Verify x86_64 is excluded from release only
- [ ] Debug config still has x86_64 (for emulator testing)

### Build Testing
```bash
flutter clean
flutter pub get
flutter build apk --release
```

- [ ] Build completes without errors
- [ ] APK size reduced to ~155-160 MB
- [ ] Size breakdown shows NO x86_64 folder

### APK Verification
```bash
# Extract and check architectures
cd /tmp && unzip -o ~/Downloads/WowCare/wowcare2-mobile/build/app/outputs/apk/release/app-release.apk > /dev/null 2>&1
ls lib/
# Should show: arm64-v8a/, armeabi-v7a/ (no x86_64)
```

- [ ] APK contains only arm64-v8a and armeabi-v7a
- [ ] Size per architecture:
  - arm64-v8a: ~60 MB ✅
  - armeabi-v7a: ~70 MB ✅
  - No x86_64 ❌ (should be gone)

---

## Phase 2: Flutter Build Flag Optimization

### Implementation
```bash
flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info=build/app/profiles \
    --tree-shake-icons
```

- [ ] Build command includes all 4 flags
- [ ] Build completes without errors
- [ ] APK size: ~152-158 MB
- [ ] Debug symbols saved to `build/app/profiles/`

### Expected Output
```
✅ Building APK ...
✅ Running Dart obfuscation ...
✅ Splitting debug info ...
✅ Tree-shaking icons ...
✅ APK ready: app-release.apk (152 MB)
```

- [ ] No build warnings about missing symbols
- [ ] All obfuscation messages appear
- [ ] Debug info successfully extracted

---

## Phase 3: Functional Testing (CRITICAL)

### Install APK
```bash
# Find device
adb devices

# Install
adb install -r build/app/outputs/apk/release/app-release.apk

# Check installation
adb shell pm list packages | grep wowcare
```

- [ ] APK installs successfully
- [ ] No installation errors
- [ ] App appears in app list

### Launch & Stability
- [ ] App launches without crashes
- [ ] Splash screen appears
- [ ] Login screen loads
- [ ] No red error screens
- [ ] No immediate exceptions in logcat

### Feature Testing (Test Each)

#### Navigation & Screens
- [ ] Dashboard loads
- [ ] Can navigate between screens
- [ ] No frozen/hung screens
- [ ] Back button works
- [ ] Deep links work (if used)

#### Video Playback (if used)
- [ ] Video player initializes
- [ ] Can play videos
- [ ] No crashes during playback
- [ ] Seek/pause/resume work
- [ ] Video quality choices work

#### PDF Viewing (if used)
- [ ] PDF opens without crashes
- [ ] Can scroll/zoom
- [ ] Navigation works while PDF open
- [ ] No memory issues

#### QR Scanning (tested actively)
- [ ] QR scanner opens
- [ ] Can detect QR codes
- [ ] Scanning completes
- [ ] Results processed correctly

#### Media Operations
- [ ] Image picker opens
- [ ] File picker opens
- [ ] Can select media
- [ ] Media preview works
- [ ] Upload/process works

#### Database Operations
- [ ] Isar database initializes
- [ ] Can read/write data
- [ ] Data persists across restarts
- [ ] No database corruption

#### Firebase
- [ ] Firebase initializes
- [ ] Can authenticate
- [ ] Firestore queries work
- [ ] Cloud storage access works
- [ ] Push notifications work

#### Permissions
- [ ] Can request camera permission
- [ ] Can request location permission
- [ ] Can request file access permission
- [ ] Permissions remembered correctly

#### API Calls
- [ ] Can make API requests
- [ ] Responses parse correctly
- [ ] Error handling works
- [ ] Network errors handled gracefully

### Memory & Performance
- [ ] App doesn't crash with low memory
- [ ] Navigation smooth (no stuttering)
- [ ] No excessive memory usage
- [ ] Battery drain is normal

### Edge Cases
- [ ] App resumes from background
- [ ] App survives process kill/restart
- [ ] Rotation changes work
- [ ] Obfuscated code doesn't cause bugs

### Logcat Monitoring
```bash
adb logcat | grep -i "error\|crash\|exception"
```

- [ ] No unexpected errors
- [ ] No native crashes
- [ ] No unhandled exceptions
- [ ] Warnings are acceptable

---

## Phase 4: Size Verification

### APK Size Checks
```bash
ls -lh build/app/outputs/apk/release/app-release.apk
# Expected: 152-158 MB
```

- [ ] APK size: **152-158 MB** ✅
- [ ] Size reduction: **-65 to -71 MB** ✅
- [ ] Size reduction percentage: **29-32%** ✅

### APK Breakdown
```bash
cd /tmp
unzip -o ~/path/to/app-release.apk > /dev/null 2>&1
du -sh lib/ assets/ classes*.dex resources.arsc
```

- [ ] lib/ size: ~130-135 MB (was 198 MB)
- [ ] assets/ size: ~23 MB (unchanged)
- [ ] classes.dex size: ~8 MB (unchanged)
- [ ] resources.arsc size: ~1.4 MB (unchanged)

### Architecture Breakdown
```bash
du -sh lib/*/
```

- [ ] arm64-v8a: ~60 MB ✅
- [ ] armeabi-v7a: ~72 MB ✅
- [ ] NO x86_64 ❌ (must be removed)

---

## Phase 5: Advanced Optimizations (Optional)

### FFmpeg Optimization (If Applicable)

#### Before Removing FFmpeg
- [ ] Confirmed FFmpeg is actually used
- [ ] Identified FFmpeg usage patterns
- [ ] Have plan for removing

#### After Removing FFmpeg
```bash
flutter pub get
flutter clean
flutter build apk --release --obfuscate --split-debug-info=build/app/profiles --tree-shake-icons
```

- [ ] Build succeeds
- [ ] No compilation errors
- [ ] APK size: ~125-130 MB (additional -25 MB)
- [ ] Video playback still works (uses video_player)
- [ ] All video features work

### Asset Optimization (If Done)

#### Image Conversion
- [ ] PNG → WebP conversion script ran
- [ ] Verified WebP images display correctly
- [ ] Removed original PNG files
- [ ] APK size: ~117-122 MB (additional -5-8 MB)

#### Image Compression
- [ ] JPG images compressed
- [ ] Visual quality acceptable
- [ ] No noticeable degradation
- [ ] APK size reduced further

### Dependency Cleanup (If Done)

- [ ] Identified unused dependencies
- [ ] Removed from pubspec.yaml
- [ ] No build errors
- [ ] No missing imports
- [ ] App still functional
- [ ] APK size: ~115-120 MB

---

## Phase 6: Release Build Verification

### Build with All Flags
```bash
flutter clean
flutter pub get
flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info=build/app/profiles \
    --tree-shake-icons \
    -v 2>&1 | tee build.log
```

- [ ] No ProGuard errors
- [ ] No obfuscation warnings
- [ ] All symbols processed
- [ ] Build completed successfully

### Sign APK (Production)
```bash
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
    -keystore release.jks \
    build/app/outputs/apk/release/app-release.apk alias_name
```

- [ ] APK signed successfully
- [ ] File size unchanged
- [ ] Ready for distribution

### Build AAB (Google Play)
```bash
flutter build appbundle \
    --release \
    --obfuscate \
    --split-debug-info=build/app/profiles \
    --tree-shake-icons
```

- [ ] AAB builds successfully
- [ ] AAB size: **25-35 MB** (for arm64-v8a)
- [ ] Size is expected (much smaller than APK)
- [ ] Ready for Google Play Console

---

## Phase 7: Analytics & Metrics

### Size Comparison

| Metric | Before | After (P1) | After (P1+P2) | Target |
|--------|--------|-----------|---------------|--------|
| APK | 223 MB | 158 MB | 152-158 MB | <70 MB |
| AAB | ~150 MB | ~105 MB | ~100 MB | <40 MB |
| arm64-v8a | 61 MB | 60 MB | 45-50 MB | - |
| armeabi-v7a | 72 MB | 72 MB | 50-55 MB | - |
| x86_64 | 65 MB | 0 MB | 0 MB | 0 MB |
| Savings | - | -65 MB | -65 to -70 MB | -153 MB |

### Reduction Percentage

- Phase 1 (ABI): **29.1%** reduction ✅
- Phase 1+2 (Flags): **30.5%** reduction ✅
- Phase 1+2+FFmpeg: **43.5%** reduction ✅
- Phase 1+2+Assets: **37.2%** reduction ✅
- All optimizations: **46-50%** reduction 🎯

### Performance Impact

- [ ] Startup time: **No change** (obfuscation doesn't affect runtime)
- [ ] Memory usage: **Slightly better** (less code loaded)
- [ ] Battery drain: **No change** (same logic, just obfuscated)
- [ ] Crash reporting: **Still works** (symbols stored separately)

---

## Rollback Instructions

If anything breaks:

```bash
# Restore original files
git checkout android/app/build.gradle.kts
git checkout pubspec.yaml

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

---

## Final Checklist Before Release

- [ ] All features tested and working
- [ ] App doesn't crash
- [ ] APK size reduced appropriately
- [ ] No ProGuard/R8 errors
- [ ] Debug symbols extracted
- [ ] Ready for Google Play submission
- [ ] Team informed of changes
- [ ] Release notes updated

---

## Success Criteria

✅ **Minimum (Baseline):**
- APK size: < 160 MB (was 223 MB)
- All features working
- No crashes

✅ **Recommended:**
- APK size: < 130 MB (with FFmpeg replacement)
- AAB size: < 40 MB
- All features working
- Performance acceptable

✅ **Optimal:**
- APK size: < 120 MB (with all optimizations)
- AAB size: < 30 MB
- All features working
- Excellent performance

---

## Issue Resolution Guide

### Issue: App crashes after optimization

**Solution:**
1. Check logcat for specific error
2. If "ClassNotFound" error, add to proguard-rules.pro:
   ```pro
   -keep class com.your.ClassName { *; }
   ```
3. Rebuild

### Issue: FFmpeg functions don't work after removal

**Solution:**
1. Check if you actually need FFmpeg
2. If only playing videos, remove FFmpeg and rely on video_player
3. If encoding videos, use ffmpeg_kit_flutter_min instead

### Issue: Images look bad after WebP conversion

**Solution:**
1. Increase WebP quality: `cwebp -q 90` (instead of 85)
2. Or revert to original PNG for problematic images

### Issue: ProGuard errors during build

**Solution:**
1. Run build with verbose flag: `flutter build apk --release -v`
2. Check what class is missing
3. Add keep rule to proguard-rules.pro:
   ```pro
   -keep class yourpackage.YourClass { *; }
   ```

### Issue: Debug symbols not extracting

**Solution:**
```bash
# Ensure directory exists
mkdir -p build/app/profiles

# Rebuild with verbose
flutter build apk --release --split-debug-info=build/app/profiles -v
```

---

## Production Deployment Checklist

- [ ] All tests passed
- [ ] Size optimization verified
- [ ] Performance acceptable
- [ ] Ready for Play Store
- [ ] Version bumped (pubspec.yaml)
- [ ] Release notes prepared
- [ ] Team notified
- [ ] Backup of previous version saved

---

**Status: Ready for Optimization** ✅

Start with Phase 1 in `SIZE_OPTIMIZATION_QUICK_START.md`

