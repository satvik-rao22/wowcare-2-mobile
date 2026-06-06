# Kiosk Dashboard Refresh Fix - Deployment Guide

## Overview
This fix addresses critical issues where the kiosk dashboard would lose UI elements (QR code, school name) after attendance actions and had no auto-refresh mechanism.

**Status**: Ready for testing and deployment
**Branch**: hotfix/kiosk
**Priority**: High

---

## What Was Fixed

### 1. QR Code & School Name Disappearing ✅
- **Problem**: After completing student/staff sign-in/out, the dashboard would show blank/empty areas
- **Root Cause**: `kiosk_qr_section_widget.dart` returned `SizedBox.shrink()` for unhandled states
- **Solution**: Always show loading state instead of collapsing the widget

### 2. Dashboard Not Refreshing After Attendance ✅
- **Problem**: Users would return to dashboard with stale data
- **Root Cause**: No automatic refresh mechanism when navigating back
- **Solution**: Added `didChangeDependencies()` callback and app lifecycle observer

### 3. No Manual Refresh Option ✅
- **Problem**: Users had no way to refresh if data seemed stale
- **Root Cause**: No pull-to-refresh UI
- **Solution**: Added `RefreshIndicator` for pull-down refresh

---

## Files Modified

```
lib/presentation/features/kiosk/widgets/kiosk_qr_section_widget.dart
  - Line 49, 56: Fix fallback from SizedBox.shrink() to _buildLoadingState()

lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart
  - Line 33: Add WidgetsBindingObserver
  - Lines 35-37: Add instance variables for caching
  - Lines 40-50: Enhance initState with observer and logging
  - Lines 53-60: Add didChangeAppLifecycleState
  - Lines 62-76: Add didChangeDependencies
  - Lines 78-81: Extract _loadQrCode method
  - Lines 83-87: Add _refreshDashboard for pull-to-refresh
  - Lines 89-93: Add dispose with observer cleanup
  - Lines 174-186: Wrap body in RefreshIndicator
  - Lines 250-277: Enhance _getSchoolName with caching
  - Lines 325-326, 367-368: Add attendance completion logs

lib/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart
  - Enhanced logging (already committed on branch)

lib/presentation/features/kiosk/view/kiosk_dashboard_screen_optimized.dart
  - Minor cleanup (already committed on branch)
```

---

## Build & Test Checklist

### Pre-Build
- [ ] Pull latest changes on hotfix/kiosk branch
- [ ] Run `flutter pub get`
- [ ] Run `flutter clean`
- [ ] Verify no syntax errors: `flutter analyze`

### Build
- [ ] Build APK: `flutter build apk --release`
- [ ] Build iOS: `flutter build ios --release` (or `flutter build ipa`)
- [ ] Verify build completes without errors

### Unit/Widget Tests (Optional)
- [ ] Run existing tests: `flutter test`
- [ ] Verify no new test failures

---

## Testing on Device

### Test Environment Setup
1. Install app on device/emulator
2. Login with kiosk credentials to reach Kiosk Dashboard
3. Have test data available:
   - Student PIN with signed-out students
   - Student PIN with signed-in students
   - Staff PIN with signed-out staff
   - Staff PIN with signed-in staff

### Core Scenarios to Test

#### Scenario 1: Student Sign-In Flow
1. Dashboard shows QR + school name
2. Enter PIN for student account
3. Complete student sign-in
4. Return to dashboard
   - ✅ School name visible immediately
   - ✅ QR shows loading spinner briefly
   - ✅ Fresh QR code loads
   - ✅ No cached/stale data

#### Scenario 2: Staff Sign-In Flow
1. Dashboard shows QR + school name
2. Enter PIN for staff (not signed in)
3. Complete staff sign-in
4. Return to dashboard
   - ✅ School name visible
   - ✅ QR refreshes
   - ✅ Fresh data displayed

#### Scenario 3: Manual Refresh
1. Dashboard showing QR
2. Pull down on screen (drag from top)
   - ✅ Refresh indicator appears
   - ✅ QR refreshes
   - ✅ School name visible
   - ✅ Indicator dismisses automatically

#### Scenario 4: App Background/Foreground
1. On dashboard
2. Press home button (app to background)
3. Wait 5-10 seconds
4. Return to app
   - ✅ Dashboard visible with school name
   - ✅ QR loading spinner appears
   - ✅ Fresh QR loads

#### Scenario 5: Error Handling
1. Disconnect network
2. Trigger refresh
   - ✅ Error state shows school name (NOT blank)
   - ✅ Error message displayed
   - ✅ QR area not collapsed

### Debug Logs to Verify
When testing, check console logs for:
- `[KIOSK] Dashboard opened`
- `[KIOSK] Dashboard refresh requested (initState)`
- `[KIOSK] Dashboard resumed`
- `[KIOSK] Refreshing QR`
- `[KIOSK] Refreshing school info`
- `[KIOSK] Refresh requested (pull-to-refresh)`
- `[KIOSK] Attendance action completed (Student/Staff)`

---

## Rollback Plan

If issues are discovered:

1. **Immediate Rollback**:
   ```bash
   git revert <commit-hash>
   git push
   ```

2. **Quick Fixes** (if issues are minor):
   - Check `KIOSK_DASHBOARD_REFRESH_FIX.md` for explanations
   - Refer to specific code changes in `KIOSK_FIX_SUMMARY.md`
   - May need to adjust logging levels or timing

3. **Investigation**:
   - Enable all debug logs: `AppLogger.d()` messages should appear
   - Check `didChangeDependencies()` is being called
   - Verify `RefreshIndicator` is responding to swipes
   - Confirm cubit state transitions are correct

---

## Known Limitations

1. **Manual Refresh Timing**: Pull-to-refresh may take 1-2 seconds while QR is being fetched from API
2. **School Name Cache**: If school name changes during app session, it won't update until next QR load
3. **Error States**: Error states will retry but don't have exponential backoff

---

## Performance Considerations

1. **Multiple Refreshes**: Flag `_isRefreshingQr` prevents race conditions
2. **Memory**: School name cache is minimal (single string)
3. **Network**: Each refresh makes one API call (expected behavior)
4. **UI**: `RepaintBoundary` keeps QR rendering isolated

---

## Success Criteria

✅ QR code ALWAYS visible (never collapsed)
✅ School name ALWAYS visible (never blank)
✅ Dashboard refreshes on return from sign-in/sign-out
✅ Dashboard refreshes on app foreground
✅ Manual refresh works (pull-to-refresh)
✅ Debug logs show expected messages
✅ No crashes or errors in console
✅ All test scenarios pass

---

## Post-Deployment Monitoring

1. **Monitor Crash Logs**: Check for any new crashes related to kiosk
2. **Monitor User Reports**: Watch for reports of missing QR/school name
3. **Monitor Performance**: QR loading time should be acceptable
4. **Keep Logs**: Archive debug logs for analysis if issues arise

---

## Documentation Files

- `KIOSK_DASHBOARD_REFRESH_FIX.md` - Detailed root cause analysis and fixes
- `KIOSK_FIX_SUMMARY.md` - Code changes breakdown
- `KIOSK_VERIFICATION_CHECKLIST.md` - Comprehensive test checklist
- `DEPLOYMENT_GUIDE.md` - This file

---

## Questions/Issues?

1. Review root cause analysis in `KIOSK_DASHBOARD_REFRESH_FIX.md`
2. Check specific code changes in `KIOSK_FIX_SUMMARY.md`
3. Run through verification checklist in `KIOSK_VERIFICATION_CHECKLIST.md`
4. Enable debug logging to see flow: `[KIOSK]` messages

---

## Git Commit Message (if needed)

```
Fix: Kiosk dashboard auto-refresh and UI element preservation

- Fix QR code disappearing by never returning SizedBox.shrink() as fallback
- Fix school name disappearing by caching value across state changes
- Add auto-refresh when returning to dashboard via didChangeDependencies()
- Add auto-refresh when app comes to foreground via lifecycle observer
- Add manual pull-to-refresh support via RefreshIndicator
- Add structured debug logging for troubleshooting
- Ensure dashboard always shows school name (never blank)
- Ensure QR area always visible (never collapsed)

Fixes: [ISSUE_NUMBER]

Test Plan:
- Student sign-in/sign-out → return to dashboard → QR visible
- Staff sign-in/sign-out → return to dashboard → QR visible
- Pull-down refresh → dashboard refreshes correctly
- App background/foreground → QR refreshes
- Error states → school name still visible
```

---

## Next Steps

1. ✅ Code review by team
2. ⏳ Merge to hotfix/kiosk
3. ⏳ Build and test on device
4. ⏳ Merge to develop
5. ⏳ Release with next version
