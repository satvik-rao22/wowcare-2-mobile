# App Size Optimization - Action Plan & Summary

## Current State

**APK Size:** 223 MB (Release Build)  
**Target:** 30-50 MB (or minimum 50-70 MB conservatively)  
**Reduction Required:** 65-75%

**Root Cause Breakdown:**
- **198 MB (89%)** - Native libraries (.so files)
  - **65 MB** - x86_64 architecture (emulator only, unnecessary)
  - **35 MB** - FFmpeg codec libraries (if not used or replaceable)
  - **58.9 MB** - Dart/Flutter runtime
  - **8 MB** - Other native libraries
- **8.1 MB (3.6%)** - Java/Dart bytecode
- **23 MB (10%)** - Assets (images, fonts, animations)
- **1.4 MB** - Resources manifest

---

## Implementation Roadmap

### PHASE 1: IMMEDIATE (Today - 30 minutes)
**Guaranteed savings: -65 MB (-29%)**

#### Action 1.1: Fix ABI Filtering
- **File:** `android/app/build.gradle.kts` (lines 56-78)
- **Change:** Add `ndk { abiFilters.clear(); ... }` to buildTypes.release
- **Removes:** x86_64 architecture from release build
- **Time:** 5 minutes
- **Risk:** None
- **Savings:** -65 MB

#### Action 1.2: Enable Build Optimizations
- **Command:**
  ```bash
  flutter build apk \
      --release \
      --obfuscate \
      --split-debug-info=build/app/profiles \
      --tree-shake-icons
  ```
- **Time:** 5 minutes (setup) + 3-5 minutes (build)
- **Risk:** None
- **Savings:** -3 MB
- **Creates:** Optimized APK + debug symbols

#### Action 1.3: Verify
- **Check:** APK size should be ~150-158 MB (vs 223 MB)
- **Verify:** APK contains only arm64-v8a and armeabi-v7a
- **Test:** Install on real device, test all features
- **Time:** 10-15 minutes

**Phase 1 Result:** 223 MB → ~158 MB (-65 MB, -29%)

---

### PHASE 2: CONDITIONAL (Next 1-2 days)
**Additional potential savings: -25 to -35 MB (-11% to -15%)**

#### Option A: Analyze & Replace FFmpeg (-25 MB if replaced)

**Prerequisites:**
1. Identify FFmpeg usage in code:
   ```bash
   grep -r "ffmpeg\|FFmpeg" lib/ --include="*.dart" | grep -v "import 'dart:async'"
   ```

2. Determine actual functionality needed:
   - Video playback only? → Replace with `video_player`
   - Video encoding? → Replace with `ffmpeg_kit_flutter_min`
   - Not used? → Remove completely

**Actions (choose one):**

**Option A1: Remove FFmpeg (if not used)**
- Remove `ffmpeg_kit_flutter_new_https: ^2.1.0` from pubspec.yaml
- Run `flutter pub get && flutter clean`
- Rebuild
- **Time:** 5 minutes
- **Savings:** -25 to -35 MB
- **Risk:** None if FFmpeg not used

**Option A2: Replace with video_player (if only playing videos)**
- Remove `ffmpeg_kit_flutter_new_https` from pubspec.yaml
- Use existing `video_player: ^2.10.1`
- Remove any FFmpeg-specific code
- Run `flutter pub get && flutter clean`
- Rebuild
- **Time:** 10 minutes
- **Savings:** -20 to -25 MB
- **Risk:** Low (video_player is standard)

**Option A3: Use FFmpeg Minimal (if encoding needed)**
- Replace `ffmpeg_kit_flutter_new_https: ^2.1.0` with `ffmpeg_kit_flutter_min: ^2.1.0`
- Run `flutter pub get && flutter clean`
- Rebuild (ensure only basic codecs needed)
- **Time:** 5 minutes
- **Savings:** -15 to -20 MB
- **Risk:** Medium (only supports basic codecs)

---

#### Option B: Optimize Assets (-5 to -10 MB)

**Convert PNG to WebP:**
```bash
# Install tools
brew install webp  # macOS
# or: sudo apt install webp  # Linux

# Convert images
find assets/ -name "*.png" -type f ! -name "*.9.png" | while read f; do
    cwebp -q 85 "$f" -o "${f%.png}.webp"
done
```

**Compress JPG:**
```bash
find assets/ -name "*.jpg" | while read f; do
    jpegoptim -m 85 --strip-all "$f"
done
```

**Remove duplicates:**
```bash
find assets/ -type f -exec md5sum {} \; | sort | uniq -d -w 32
```

**Optimize Lottie files:**
- Open in Lottie Editor
- Reduce keyframes
- Optimize animations

**Time:** 30-60 minutes  
**Savings:** -5 to -10 MB  
**Risk:** Low (visual quality minimal impact with q=85)

---

#### Option C: Remove Unused Dependencies (-2 to -5 MB)

**Audit:**
```bash
# Check actual usage
grep -r "import.*better_player_plus" lib/ || echo "better_player_plus NOT USED"
grep -r "import.*thumbnailer" lib/ || echo "thumbnailer NOT USED"
grep -r "import.*flutter_tindercard" lib/ || echo "flutter_tindercard NOT USED"
```

**Remove unused from pubspec.yaml:**
- Check if `better_player_plus` vs `video_player` (pick one)
- Check if `carousel_slider` vs `flutter_card_swiper` (pick one)
- Remove `thumbnailer` if video thumbnails not used
- Remove `any_link_preview` if link previews not used

**Time:** 20 minutes  
**Savings:** -2 to -5 MB  
**Risk:** Low

---

#### Option D: Remove PDF Library (-8 to -10 MB, if not used)

**Check if PDF viewing is used:**
```bash
grep -r "flutter_pdfview\|pdf" lib/ --include="*.dart"
```

**If not used:**
- Remove `flutter_pdfview: ^1.3.4` from pubspec.yaml
- Run `flutter pub get && flutter clean`
- Rebuild
- **Savings:** -8 to -10 MB

**If used but not critical:**
- Use OS native PDF viewer instead
- Use `url_launcher` to open with system app
- Remove flutter_pdfview
- **Savings:** -8 to -10 MB

**Time:** 10 minutes (if not used), 30 minutes (if need to rework code)  
**Risk:** Medium (depends on feature importance)

---

**Phase 2 Result:**
- Conservative (just ABI + Flags): 158 MB
- With Option A: 133 MB (or lower)
- With Option A + B: 125 MB
- With All Options: 110-120 MB

---

## Recommended Path (Least Risk, Most Savings)

1. **Phase 1 (Do Immediately)** - 30 minutes, -65 MB
   - Fix ABI filtering
   - Enable build flags
   - Verify on real device
   
2. **Phase 2 (Next 1-2 days)** - 30-60 minutes, additional -25 MB
   - Analyze FFmpeg usage
   - If not used, remove (-25 MB)
   - If used for playback, replace with video_player (-25 MB)
   - If used for encoding, switch to ffmpeg_kit_flutter_min (-15 MB)

3. **Phase 2 Optional (Nice to have)** - 30-60 minutes, additional -5 MB
   - Optimize assets (PNG → WebP, compress JPG)
   - Remove unused dependencies

**Final Expected Size: 100-130 MB APK, 25-40 MB AAB**

---

## Quick Reference Table

| Priority | Action | Time | Savings | Risk | Done? |
|----------|--------|------|---------|------|-------|
| 1 | Fix ABI filtering | 5 min | -65 MB | None | ⬜ |
| 1 | Enable build flags | 10 min | -3 MB | None | ⬜ |
| 1 | Test on device | 15 min | - | None | ⬜ |
| 2 | Analyze FFmpeg | 10 min | - | None | ⬜ |
| 2 | Remove/replace FFmpeg | 10 min | -15-25 MB | Medium | ⬜ |
| 2 | Optimize assets | 60 min | -5-10 MB | Low | ⬜ |
| 2 | Cleanup deps | 20 min | -2-5 MB | Low | ⬜ |
| 3 | Remove PDF (if unused) | 10 min | -8-10 MB | Medium | ⬜ |

---

## Step-by-Step Quick Start

### Day 1 (Today) - Phase 1

```bash
# 1. Edit android/app/build.gradle.kts
# Add to buildTypes.release:
# ndk { abiFilters.clear(); abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a")) }

# 2. Clean and build
flutter clean
flutter pub get
flutter build apk --release --obfuscate --split-debug-info=build/app/profiles --tree-shake-icons

# 3. Check size
ls -lh build/app/outputs/apk/release/app-release.apk
# Expected: ~150-158 MB

# 4. Test on device
adb install -r build/app/outputs/apk/release/app-release.apk
# Test all features

# 5. Verify APK contents
cd /tmp
unzip -o ~/Downloads/WowCare/wowcare2-mobile/build/app/outputs/apk/release/app-release.apk > /dev/null 2>&1
du -sh lib/*/
# Should see: arm64-v8a, armeabi-v7a (NO x86_64)
```

**Result: 223 MB → ~158 MB (-65 MB)**

---

### Day 2 (Next) - Phase 2

```bash
# 1. Check FFmpeg usage
grep -r "ffmpeg" lib/ --include="*.dart" | head -20

# 2. Based on usage:
# If not used:
#   - Remove ffmpeg_kit_flutter_new_https from pubspec.yaml
# If only playback:
#   - Remove ffmpeg_kit_flutter_new_https (video_player is enough)
# If encoding:
#   - Replace with ffmpeg_kit_flutter_min

# 3. Rebuild
flutter clean
flutter pub get
flutter build apk --release --obfuscate --split-debug-info=build/app/profiles --tree-shake-icons

# 4. Check new size
ls -lh build/app/outputs/apk/release/app-release.apk
# Expected: ~130 MB (additional -25 MB savings)

# 5. Test thoroughly
adb install -r build/app/outputs/apk/release/app-release.apk
# Test video playback, encoding, all features
```

**Result: 158 MB → ~130 MB (additional -25 MB)**

---

## Files to Read

1. **START HERE:** `SIZE_OPTIMIZATION_QUICK_START.md` (5 min read)
2. **DEEP DIVE:** `APP_SIZE_OPTIMIZATION_AUDIT.md` (15 min read)
3. **IMPLEMENTATION:** `APP_SIZE_OPTIMIZATION_IMPLEMENTATION.md` (30 min read)
4. **VERIFICATION:** `APP_SIZE_OPTIMIZATION_CHECKLIST.md` (reference)

---

## Expected Results Summary

### Conservative Estimate (Phase 1 Only)
- **Current:** 223 MB APK, ~150 MB AAB
- **Target:** 158 MB APK, ~105 MB AAB
- **Savings:** -65 MB, -45 MB AAB (-29%, -30%)
- **Time:** 30 minutes
- **Risk:** None

### Recommended (Phase 1 + 2A)
- **Current:** 223 MB APK
- **Target:** 130 MB APK, ~40 MB AAB
- **Savings:** -93 MB, -110 MB AAB (-42%, -73%)
- **Time:** 1-2 hours
- **Risk:** Low to Medium

### Aggressive (Phase 1 + 2A + 2B)
- **Current:** 223 MB APK
- **Target:** 120 MB APK, ~35 MB AAB
- **Savings:** -103 MB, -115 MB AAB (-46%, -77%)
- **Time:** 2-3 hours
- **Risk:** Low

### Maximum (All optimizations including dropping armeabi-v7a)
- **Current:** 223 MB APK
- **Target:** 60 MB APK, ~20 MB AAB (arm64-v8a only)
- **Savings:** -163 MB, -130 MB AAB (-73%, -87%)
- **Time:** 3-4 hours
- **Risk:** HIGH (loses 32-bit support)

---

## Success Criteria

✅ **Phase 1 Complete:**
- APK size reduced from 223 MB to ~158 MB
- x86_64 removed from release APK
- All features work on real device
- No crashes or errors

✅ **Phase 2 Complete:**
- FFmpeg analyzed and decision made
- APK size reduced to ~130 MB (or lower)
- Assets optimized (PNG → WebP)
- All tests pass
- Ready for production

✅ **Ready for Google Play:**
- AAB size < 50 MB
- All architectures working
- All features verified
- Debug symbols extracted
- Release notes prepared

---

## Troubleshooting

**APK still 223 MB after changes?**
- Verify `ndk { abiFilters ... }` is in buildTypes.release
- Run `flutter clean` before building
- Check APK contents: `unzip -l app-release.apk | grep "lib/"`

**App crashes after optimization?**
- Check logcat for errors
- If ClassNotFound, add to proguard-rules.pro
- Rebuild with verbose: `flutter build apk --release -v`

**Build takes too long?**
- Normal (obfuscation is slow)
- Can take 5-10 minutes
- Run with `-v` to see progress

**FFmpeg functions don't work?**
- Check if you actually need FFmpeg
- Use video_player for playback (lightweight)
- Only use ffmpeg_kit_flutter_min if encoding needed

---

## Next Steps

1. ✅ Read this document (you're done!)
2. ✅ Read `SIZE_OPTIMIZATION_QUICK_START.md` (5 min)
3. ⬜ Implement Phase 1 (30 min)
4. ⬜ Test on real device (15 min)
5. ⬜ Implement Phase 2 (if needed) (1-2 hours)
6. ⬜ Deploy to Play Store

**Total time for Phase 1:** ~1 hour  
**Total time for Phase 1+2:** ~2-3 hours

---

## Important Notes

- ✅ No functionality loss with Phase 1
- ⚠️ Phase 2 requires analysis of FFmpeg usage
- ✅ Obfuscation doesn't affect runtime performance
- ✅ Debug symbols stored separately (crash reporting still works)
- ✅ AAB format is much smaller (25-40 MB vs 100-130 MB APK)
- 📊 Google Play serves device-appropriate APK (only arm64-v8a to 64-bit devices)

---

**Ready to optimize?** Start with `SIZE_OPTIMIZATION_QUICK_START.md`

