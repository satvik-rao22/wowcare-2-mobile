# Kiosk Dashboard Fix - Quick Reference

## The Problem
QR code and school name disappear after sign-in/sign-out. No automatic refresh. No manual refresh option.

## The Solution
3 key fixes across 2 files:

### Fix 1: Never Hide QR Area
**File**: `kiosk_qr_section_widget.dart` (Line 56)
```dart
// BEFORE: return const SizedBox.shrink();
// AFTER:
return _buildLoadingState();  // Always show loading state
```
**Result**: QR area always visible with school name

### Fix 2: Auto-Refresh on Return
**File**: `kiosk_dashboard_screen.dart` (Lines 62-76)
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // ... auto-refresh when returning from sub-screens
  _loadQrCode();
}
```
**Result**: Dashboard refreshes automatically after sign-in/sign-out

### Fix 3: Manual Refresh + Auto-Refresh App Lifecycle
**File**: `kiosk_dashboard_screen.dart`
```dart
// Add observer (Line 33)
with WidgetsBindingObserver

// Add lifecycle listener (Lines 53-60)
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _loadQrCode();  // Refresh when app comes to foreground
  }
}

// Add pull-to-refresh (Lines 83-87)
Future<void> _refreshDashboard() async {
  await context.read<KioskDashboardCubit>().loadQrCode();
}

// Wrap body in RefreshIndicator (Line 174)
body: RefreshIndicator(
  onRefresh: _refreshDashboard,
  // ...
)
```
**Result**: Dashboard auto-refreshes on app foreground + manual pull-to-refresh works

---

## Key Code Changes

| File | What Changed | Why | Impact |
|------|------|--------|---------|
| `kiosk_qr_section_widget.dart` | Line 56: Show loading instead of shrink | QR was hidden | QR always visible |
| `kiosk_dashboard_screen.dart` | Line 33: Add WidgetsBindingObserver | Track lifecycle | App foreground refresh |
| `kiosk_dashboard_screen.dart` | Lines 35-37: Add cache variables | Preserve school name | School name never blank |
| `kiosk_dashboard_screen.dart` | Lines 62-76: Add didChangeDependencies() | Refresh on return | Auto-refresh after sign-in/out |
| `kiosk_dashboard_screen.dart` | Lines 83-87: Add _refreshDashboard() | Manual refresh | Pull-to-refresh support |
| `kiosk_dashboard_screen.dart` | Lines 250-277: Cache school name | Preserve during refresh | School name always visible |
| `kiosk_dashboard_screen.dart` | Line 174: Add RefreshIndicator | Enable swipe refresh | Users can manually refresh |

---

## Testing Checklist

### Must Pass
- [ ] Student sign-in → return → QR visible + school name visible
- [ ] Student sign-out → return → QR visible + school name visible
- [ ] Staff sign-in → return → QR visible + school name visible
- [ ] Staff sign-out → return → QR visible + school name visible
- [ ] Pull down to refresh → works without crash
- [ ] App background/foreground → QR refreshes

### Should Not Break
- [ ] PIN pad still works
- [ ] Navigation to sign-in/sign-out screens works
- [ ] Error messages still display
- [ ] School selection/login flow unaffected

---

## Debug Logs to Watch For

```
[KIOSK] Dashboard opened              ← Screen entry
[KIOSK] Dashboard resumed             ← App foreground
[KIOSK] Dashboard resumed (didChangeDependencies)  ← Return from sub-screen
[KIOSK] Refreshing QR                 ← QR fetch started
[KIOSK] Refresh requested (pull-to-refresh)       ← Manual refresh
[KIOSK] Attendance action completed   ← Sign-in/out done
```

---

## If Something Goes Wrong

### QR Still Disappears
- Check: Is `_buildLoadingState()` being called? (Line 56)
- Check: Is fallback returning shrink instead of loading state?
- Fix: Verify line 56 has `return _buildLoadingState();` not `SizedBox.shrink()`

### School Name Still Blank
- Check: Is `_cachedSchoolName` being used? (Line 250-277)
- Check: Does `_getSchoolName()` have all the fallback cases?
- Fix: Verify it returns cached value in Loading/Error states

### Not Auto-Refreshing on Return
- Check: Is `didChangeDependencies()` being called? (Watch for logs)
- Check: Is `_isRefreshingQr` flag blocking refresh?
- Fix: Ensure override at lines 62-76 exists and calls `_loadQrCode()`

### Pull-to-Refresh Not Working
- Check: Is `RefreshIndicator` wrapping the body? (Line 174)
- Check: Is `_refreshDashboard()` defined? (Lines 83-87)
- Fix: Verify RefreshIndicator is properly nested and has onRefresh callback

### App Foreground Not Refreshing
- Check: Is `WidgetsBindingObserver` mixed in? (Line 33)
- Check: Is observer added in initState? (Line 44)
- Check: Is observer removed in dispose? (Line 91)
- Check: Is `didChangeAppLifecycleState()` implemented? (Lines 53-60)
- Fix: Ensure all observer setup/teardown is in place

---

## One-Minute Fix Verification

Run this to see if the fixes are applied:

```bash
# Check if QR always shows (never shrink)
grep -n "SizedBox.shrink" lib/presentation/features/kiosk/widgets/kiosk_qr_section_widget.dart
# ✅ Should return 0 matches (no shrink in build path)

# Check if RefreshIndicator exists
grep -n "RefreshIndicator" lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart
# ✅ Should match line ~174

# Check if didChangeDependencies exists
grep -n "didChangeDependencies" lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart
# ✅ Should match line ~62

# Check if WidgetsBindingObserver is mixed in
grep -n "WidgetsBindingObserver" lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart
# ✅ Should match line ~33
```

---

## Performance Impact

- **Network**: +1 API call per refresh (expected)
- **Memory**: +1 string cache for school name (minimal)
- **CPU**: Lifecycle observer adds minimal overhead
- **UI**: RefreshIndicator is standard Flutter widget (optimized)
- **Rendering**: RepaintBoundary on QR isolates rendering (already in place)

---

## Files to Review

1. **KIOSK_DASHBOARD_REFRESH_FIX.md** - Full root cause analysis
2. **KIOSK_FIX_SUMMARY.md** - Detailed code changes
3. **KIOSK_VERIFICATION_CHECKLIST.md** - Complete test cases
4. **DEPLOYMENT_GUIDE.md** - Deployment procedures

---

## Key Learnings

❌ **Never use `SizedBox.shrink()` as fallback** → Use loading/error state instead
✅ **Always cache critical data** → Preserve across rebuilds
✅ **Always observe lifecycle** → App background/foreground should trigger refresh
✅ **Provide manual refresh** → `RefreshIndicator` or similar
✅ **Use structured logging** → Makes debugging much easier

---

## Status

- ✅ Code changes implemented
- ✅ Documentation complete
- ✅ Ready for testing
- ⏳ Awaiting QA verification
- ⏳ Ready for deployment

---

Last Updated: 2026-06-06
Branch: hotfix/kiosk
Status: Ready for Review
