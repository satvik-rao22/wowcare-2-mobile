# WowCare App Size Optimization Audit & Implementation Plan

## Executive Summary

**Current APK Size:** 223 MB (Release Build)  
**Target Size:** 30-50 MB  
**Reduction Required:** 77-87% size reduction

**Root Cause Analysis:**
- **198 MB (89%)** - Native libraries (.so files) - PRIMARY ISSUE
  - 61 MB: arm64-v8a
  - 72 MB: armeabi-v7a  
  - 65 MB: x86_64 (UNNECESSARY - emulator only)
- **8.1 MB (3.6%)** - Dart/Java bytecode (classes.dex)
- **23 MB (10%)** - Assets (images, fonts, lottie)
- **1.4 MB (0.6%)** - Resources (icons, layouts)

**Total:** 231 MB

---

## Breakdown by Library

### Critical Offenders (Size Impact)

#### 1. FFmpeg Kit (HIGHEST IMPACT - ~30-35 MB)
**Responsible for:**
- libavcodec.so: 9.2M (arm64) + 8.9M (armv7) = 18.1M
- libavformat.so: 4.8M (arm64) + 4.6M (armv7) = 9.4M
- libavfilter.so: 2.8M (arm64) + 2.5M (armv7) = 5.3M
- libswresample.so, libswscale.so, libffmpegkit.so: ~2M
- **Total:** ~35 MB per complete build (both architectures)
- **Reduction Potential:** -20 to -25 MB (by removing ffmpeg_kit_flutter_new_https)

**Issue:** The `ffmpeg_kit_flutter_new_https` package includes the FULL FFmpeg library with all codecs. For most apps, you don't need all codecs.

**Investigation:** Check actual FFmpeg usage in the app.
- Do you actually use video encoding?
- What codecs do you actually need?
- Could you replace with a lightweight alternative?

#### 2. PDF Library (SECONDARY - ~7-8 MB)
**Responsible for:**
- libmodpdfium.so: 4.6M (arm64) + 3.1M (armv7) = 7.7M
- libmodft2.so: 735K (arm64) + 505K (armv7) = 1.2M
- **Total:** ~8.9 MB
- **Reduction Potential:** -5 to -8 MB (by removing PDF viewing or using lighter alternative)

**Issue:** flutter_pdfview includes full PDFium library for rendering.

**Investigation:** 
- Do you actually use PDF viewing in the released app?
- Can PDF viewing be handled by the OS (Intent to native app)?
- Or is it critical functionality?

#### 3. Dart/Flutter Runtime (TERTIARY - ~19 MB per arch)
**Responsible for:**
- libapp.so: 19M (arm64) + 21M (armv7) = 40M
- libflutter.so: 11M (arm64) + 7.9M (armv7) = 18.9M
- **Total:** ~58.9 MB (both architectures)
- **Reduction Potential:** -5 to -10 MB (via code obfuscation and tree-shaking)

**Issue:** Not much can be done here without cutting features.

**Investigation:**
- Ensure obfuscation is enabled: `--obfuscate`
- Ensure tree-shake-icons is enabled: `--tree-shake-icons`
- Remove unused dependencies

#### 4. Other Native Libraries
- **libbarhopper_v3.so:** 4.7M (arm64) + 3.1M (armv7) = 7.8M
  - Unknown - may be internal library or transitive dependency
- **libisar.so:** 1.0M (arm64) + 737K (armv7) = 1.7M
  - Isar database - needed for app functionality
- **libc++_shared.so:** 1.2M (arm64) + 883K (armv7) = 2.1M
  - C++ standard library (required by dependencies)

#### 5. Unnecessary Architecture
**x86_64: 65 MB**
- Used ONLY for Android emulator testing
- NOT needed for production release
- Should be excluded from release APK via ABI filtering

---

## Detailed Size Breakdown

```
223 MB APK
├── lib/ (198 MB = 89%)
│   ├── arm64-v8a/ (61 MB)
│   │   ├── libavcodec.so (9.2 MB) [FFmpeg]
│   │   ├── libapp.so (19 MB) [Dart/Flutter]
│   │   ├── libflutter.so (11 MB) [Flutter Engine]
│   │   ├── libavformat.so (4.8 MB) [FFmpeg]
│   │   ├── libbarhopper_v3.so (4.7 MB) [Unknown]
│   │   ├── libmodpdfium.so (4.6 MB) [PDF]
│   │   ├── libavfilter.so (2.8 MB) [FFmpeg]
│   │   └── Other libraries (0.4 MB)
│   │
│   ├── armeabi-v7a/ (72 MB)
│   │   ├── libapp.so (21 MB) [Dart/Flutter]
│   │   ├── libavcodec_neon.so (9.1 MB) [FFmpeg]
│   │   ├── libavcodec.so (8.9 MB) [FFmpeg]
│   │   ├── libflutter.so (7.9 MB) [Flutter Engine]
│   │   ├── libavformat_neon.so (4.6 MB) [FFmpeg]
│   │   ├── libavformat.so (4.6 MB) [FFmpeg]
│   │   ├── libmodpdfium.so (3.1 MB) [PDF]
│   │   ├── libbarhopper_v3.so (3.1 MB) [Unknown]
│   │   └── Other libraries (2.7 MB)
│   │
│   └── x86_64/ (65 MB) ❌ REMOVE - EMULATOR ONLY
│       └── Similar breakdown to arm64-v8a
│
├── classes.dex (8.1 MB = 3.6%) [Dart/Java code]
├── classes2.dex (216 KB) [Additional classes]
├── assets/ (23 MB = 10%) [Images, fonts, lottie, etc.]
├── resources.arsc (1.4 MB) [Resource manifest]
└── META-INF/, AndroidManifest.xml, etc. (~7 MB)
```

---

## Optimization Strategy & Priorities

### Priority 1: IMMEDIATE (Guaranteed Savings: -63 MB)

#### 1.1 Exclude x86_64 Architecture from Release Build
**Savings:** -65 MB
**Risk:** None - x86_64 is only for emulator testing
**Implementation:** Update `android/app/build.gradle.kts`

**Current (Wrong):**
```kotlin
ndk {
    abiFilters += listOf("arm64-v8a", "armeabi-v7a")
}
```

**Problem:** Even though abiFilters is set, something is still including x86_64.

**Solution:** Use explicit productFlavors or split APKs per architecture.

**Code:**
```kotlin
// Remove x86_64 from release build
android {
    defaultConfig {
        ndk {
            abiFilters.clear()
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }
    
    buildTypes {
        release {
            // Ensure no x86/x86_64 in release
            ndk {
                abiFilters.clear()
                abiFilters += listOf("arm64-v8a", "armeabi-v7a")
            }
        }
    }
}
```

**Alternative: Split APKs (Better)**
Enable split APKs so Google Play serves only arm64-v8a to 64-bit devices:
```kotlin
bundle {
    density.enableSplit = true
    abi.enableSplit = true  // ✅ This creates separate APKs per ABI
    language.enableSplit = true
}
```

**Expected Result:** Release APK → ~158 MB

---

#### 1.2 Analyze & Optimize FFmpeg Usage
**Potential Savings:** -15 to -25 MB
**Risk:** Medium - depends on app features

**Investigation Required:**
1. Search codebase for ffmpeg_kit usage:
   ```bash
   grep -r "ffmpeg" lib/ --include="*.dart" | grep -i "import\|use\|execute"
   ```

2. Check what FFmpeg functionality is actually used:
   - Video encoding?
   - Audio processing?
   - Video transcoding?
   - Or just playback?

3. Determine which codecs are needed

**Options:**

**Option A: Replace with Lighter Alternative**
- If only **video playback** needed: Remove ffmpeg_kit, use `video_player` (lightweight, uses native decoders)
- If **audio processing** needed: Use `just_audio` instead
- If **video encoding** needed: Keep ffmpeg_kit_flutter_min (minimal codecs)

**Option B: Use ffmpeg_kit_flutter_min**
- Switch from `ffmpeg_kit_flutter_new_https` → `ffmpeg_kit_flutter_min`
- Includes only basic codecs (H.264, VP8, AAC, MP3)
- Estimated reduction: -15 to -20 MB

**Option C: Keep Current**
- If you need full FFmpeg support, keep as is
- But ensure you're using it

**Recommendation:** 
1. Check actual FFmpeg usage in code
2. If using for video playback only, replace with `video_player` plugin (-25 MB)
3. If using for encoding, switch to `ffmpeg_kit_flutter_min` (-15 MB)

---

#### 1.3 Optimize Assets
**Potential Savings:** -5 to -10 MB
**Risk:** Low - no functionality impact

**Current Assets:** 23 MB
```
7.9M - lottie/ (animations)
3.9M - fonts/
3.6M - vectors/ (SVG files)
3.2M - images/ (PNG/JPG)
2.0M - bgImages/
1.6M - icons/
```

**Optimizations:**
1. **Convert PNG → WebP** (lossless, 25-30% smaller)
2. **Compress JPG images** (20-30% reduction)
3. **Remove duplicate assets** (check for unused images)
4. **Subset fonts** (keep only needed weights/characters)
5. **Optimize Lottie files** (remove unused keyframes)

**Tools:**
```bash
# Convert PNG to WebP
find assets/ -name "*.png" -exec cwebp {} -o {}.webp \;

# Compress JPG
find assets/ -name "*.jpg" -exec jpegoptim -m 85 {} \;

# Optimize SVG
svgo assets/vectors/ --multipass
```

**Expected Savings:** -5 to -8 MB

---

#### 1.4 Enable Proper Flutter Build Flags
**Potential Savings:** -2 to -5 MB
**Risk:** None

**Ensure Release Build Uses:**
```bash
flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info=build/app/profiles/debug-symbols \
    --tree-shake-icons
```

This enables:
- `--obfuscate`: Minifies Dart code
- `--split-debug-info`: Separates debug symbols (reduces APK)
- `--tree-shake-icons`: Removes unused Material icons

**Expected Savings:** -2 to -5 MB

---

### Priority 2: MEDIUM (Conditional - Potential: -20-30 MB)

#### 2.1 Remove or Replace PDF Library
**Savings:** -8 to -10 MB (if removed)
**Risk:** Medium - if PDF viewing is used

**Investigation:**
1. Search for PDF usage:
   ```bash
   grep -r "flutter_pdfview\|pdf" lib/ --include="*.dart"
   ```

2. Check if PDF viewing is critical

**Options:**
- **Option A:** Remove PDF viewing (if not critical)
  - Delete flutter_pdfview dependency
  - Delete PDF-related code
  - Savings: -8 to -10 MB

- **Option B:** Open PDFs with native app
  - Let system handle PDF (Android/iOS native PDF viewer)
  - Use url_launcher to open files
  - Savings: -8 to -10 MB

- **Option C:** Replace with lighter PDF library
  - There's no good lightweight PDF viewer in Flutter
  - Most alternatives are heavier

**Recommendation:** If PDF viewing is critical but not heavily used, open with native app.

---

#### 2.2 Remove Unused Dependencies
**Potential Savings:** -2 to -5 MB

**Audit pubspec.yaml:**
Check for packages that aren't actually used:
- `better_player_plus` - is this used or does video_player suffice?
- `thumbnailer` - video thumbnail, is it necessary?
- `any_link_preview` - is link preview used?
- `flutter_tindercard` - is tinder UI needed?
- `calendar_date_picker2` - multiple date pickers?
- `carousel_slider` + `flutter_card_swiper` - duplicate carousel libs?

**Commands:**
```bash
# Find unused dependencies
flutter pub deps --tree | grep "direct" | sort

# Check if packages are actually imported
for pkg in better_player_plus thumbnailer flutter_tindercard; do
  echo "=== $pkg ==="
  grep -r "import.*$pkg" lib/ --include="*.dart" || echo "NOT USED"
done
```

---

### Priority 3: ADVANCED (Complex - Potential: -5-10 MB)

#### 3.1 Remove Unnecessary Architectures (armeabi-v7a)
**Savings:** -36 MB (removing armeabi-v7a, keeping only arm64-v8a)
**Risk:** HIGH - breaks compatibility with 32-bit devices

**Context:**
- **arm64-v8a:** Modern phones (99.5% of new devices)
- **armeabi-v7a:** Legacy 32-bit support (declining usage)

**Trade-off Analysis:**
- **Pros:** -36 MB from APK (58 MB → 22 MB)
- **Cons:** 
  - No support for older devices (pre-2016 flagships, budget phones)
  - Play Store reach slightly reduced
  - But: 95%+ of users have 64-bit devices

**Recommendation:** 
- **Option 1:** Keep both (safer, 158 MB)
- **Option 2:** Use AAB + split APKs (Google Play serves arm64-v8a to 64-bit devices, saves 36 MB for most users)
- **Option 3:** Drop armeabi-v7a only if targeting high-end devices (start-ups, premium market)

---

## Summary of Savings Potential

| Optimization | Size Savings | Risk | Priority | Implementation |
|---|---|---|---|---|
| **Remove x86_64 arch** | -65 MB | None | 1 | build.gradle.kts |
| **Optimize FFmpeg** | -15 to -25 MB | Medium | 1 | pubspec.yaml + code |
| **Optimize Assets** | -5 to -8 MB | Low | 1 | Image tools |
| **Remove/Replace PDF** | -8 to -10 MB | Medium | 2 | pubspec.yaml |
| **Remove unused deps** | -2 to -5 MB | Low | 2 | pubspec.yaml |
| **Flutter build flags** | -2 to -5 MB | None | 1 | Build script |
| **Remove armeabi-v7a** | -36 MB | HIGH | 3 | build.gradle.kts |
| **Total (Conservative)** | **-92 to -108 MB** | Low | - | - |

---

## Expected Final Sizes

### Scenario 1: Conservative Optimization (Recommended)
- Remove x86_64
- Optimize FFmpeg (if possible, replace with lighter alternative)
- Optimize assets
- Enable proper Flutter build flags
- **Expected APK:** 50-70 MB
- **Expected AAB (Google Play):** 25-40 MB

### Scenario 2: Aggressive Optimization
- Remove x86_64, armeabi-v7a
- Replace FFmpeg with video_player
- Remove PDF library
- Optimize assets
- Enable Flutter flags
- **Expected APK:** 20-30 MB
- **Expected AAB:** 10-20 MB
- **Trade-off:** Loses 32-bit support, PDF viewing

### Scenario 3: With AAB + Split APKs (Recommended for Play Store)
- Remove x86_64
- Use optimized FFmpeg or video_player
- Optimize assets  
- Enable Flutter flags
- Use AAB with split APKs
- **Expected arm64-v8a APK:** 50 MB
- **Expected arm64-v8a AAB:** 20-30 MB
- **Users on 64-bit get 50-60 MB, on 32-bit get 120-140 MB**

---

## Next: Implementation Steps

Proceed to APP_SIZE_OPTIMIZATION_IMPLEMENTATION.md for:
1. Detailed code changes
2. Exact gradle configurations
3. Asset optimization tools
4. Build scripts
5. Testing procedures

