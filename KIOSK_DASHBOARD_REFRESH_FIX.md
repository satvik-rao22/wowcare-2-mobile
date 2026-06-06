# Kiosk Dashboard Refresh & State Preservation Fix

## Root Cause Analysis

### Issue #1: QR Code and School Name Disappearing After Sign-In/Sign-Out
**Root Cause**: `kiosk_qr_section_widget.dart` line 53 returned `SizedBox.shrink()` for unhandled states.

When the cubit state was:
- `KioskDashboardInitial` (initial state before QR load)
- `KioskDashboardPinSuccess` (after PIN verification completes)
- Any other unexpected state

The entire QR section widget collapsed to zero size, hiding:
- School name
- QR code area
- Loading indicators

**Why this happened**: The widget only explicitly handled:
- `KioskDashboardLoading` ✓
- `KioskDashboardError` ✓
- `KioskDashboardQrLoaded` ✓
- `KioskDashboardPinValidating` ✓

But returned `SizedBox.shrink()` as a fallback (line 53), which was triggered when:
1. Screen initially loaded (before loadQrCode callback fires)
2. PIN was verified (state = PinSuccess, before screen transition)

### Issue #2: No Automatic Refresh When Returning to Dashboard
**Root Cause**: Navigation patterns and state management gaps.

When user completed sign-in/sign-out:
1. Cubit was in `KioskDashboardPinSuccess` state
2. User navigated to `/kiosk/student-sign-in-and-sign-out` or `/kiosk/staff-sign-in`
3. After completion, navigated back to `/kiosk` using `context.go('/kiosk')`
4. GoRouter replaced the route (not a push/pop), so `didChangeDependencies()` might not reliably trigger
5. Cubit still held old `PinSuccess` state with stale data
6. Dashboard displayed cached/stale information

### Issue #3: No Manual Refresh Option
**Root Cause**: No pull-to-refresh mechanism.

Users had no way to manually refresh the dashboard if stale data was displayed.

---

## Fixes Implemented

### Fix #1: Never Hide QR Area (kiosk_qr_section_widget.dart)

**Changed**: Line 53 from `return const SizedBox.shrink();` to show loading state

```dart
// BEFORE (line 53)
return const SizedBox.shrink();

// AFTER (lines 53-56)
// NEVER return SizedBox.shrink - always show QR area with loading state
// This handles KioskDashboardInitial and KioskDashboardPinSuccess states
AppLogger.d('[Kiosk] Unhandled state (${state.runtimeType}) - showing loading state');
return _buildLoadingState();
```

**Effect**:
- QR section is ALWAYS visible
- School name is ALWAYS displayed (from cache or current state)
- Loading indicator shows when QR is being fetched
- Never collapses, never hides content

**States now handled**:
- ✓ `Initial` → shows "Loading QR Code..." with cached school name
- ✓ `Loading` → shows "Loading QR Code..." with cached school name
- ✓ `QrLoaded` → shows QR and school name
- ✓ `Error` → shows error message with school name
- ✓ `PinValidating` → shows QR if available, or loading state
- ✓ `PinSuccess` → shows loading state until QR refresh completes

### Fix #2: Auto-Refresh on Return to Dashboard (kiosk_dashboard_screen.dart)

**Enhanced** `didChangeDependencies()` to reliably trigger when returning from sub-screens:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  AppLogger.d('[KIOSK] Dashboard resumed (didChangeDependencies)');
  if (!_isRefreshingQr) {
    _isRefreshingQr = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.d('[KIOSK] Refreshing school info');
      _loadQrCode();
      _isRefreshingQr = false;
    });
  }
}
```

**Triggers when**:
- Screen is re-entered after navigation away
- GoRouter replaces route
- Pop navigation occurs
- Dependencies change (inherited widgets update)

### Fix #3: Pull-to-Refresh Support (kiosk_dashboard_screen.dart)

**Added** `RefreshIndicator` to body and `_refreshDashboard()` method:

```dart
body: RefreshIndicator(
  onRefresh: _refreshDashboard,
  child: BlocBuilder<KioskDashboardCubit, KioskDashboardState>(
    // ...
  ),
),

Future<void> _refreshDashboard() async {
  AppLogger.d('[KIOSK] Refresh requested (pull-to-refresh)');
  await context.read<KioskDashboardCubit>().loadQrCode();
}
```

**Allows users to**:
- Pull down on the dashboard screen
- Manually refresh school data, QR code, and kiosk configuration
- See updated data immediately

### Fix #4: Comprehensive Debug Logging (kiosk_dashboard_screen.dart)

Added structured logs for tracking:
- `[KIOSK] Dashboard opened` - Screen entry
- `[KIOSK] Dashboard resumed` - App foreground
- `[KIOSK] Dashboard resumed (didChangeDependencies)` - Re-entry from sub-screen
- `[KIOSK] Refreshing school info` - QR refresh in progress
- `[KIOSK] Refreshing QR` - QR fetch started
- `[KIOSK] Refresh requested (pull-to-refresh)` - Manual refresh
- `[KIOSK] Attendance action completed (Student/Staff)` - Action completion
- `[KIOSK] Triggering dashboard refresh` - Refresh initiated after action

---

## Files Modified

### 1. lib/presentation/features/kiosk/widgets/kiosk_qr_section_widget.dart
- **Line 53-56**: Changed fallback from `SizedBox.shrink()` to `_buildLoadingState()`
- **Effect**: QR area always visible, never collapses

### 2. lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart
- **Lines 42, 48, 57, 66, 71, 79**: Added debug logs
- **Lines 83-87**: Added `_refreshDashboard()` method for pull-to-refresh
- **Lines 174-186**: Wrapped body in `RefreshIndicator` widget
- **Effect**: Auto-refresh on return + pull-to-refresh support + better debugging

---

## How It Works Now

### Scenario: Student Sign-In Flow

1. **Dashboard opens**
   - `initState()` → calls `_loadQrCode()` in post-frame callback
   - Logs: `[KIOSK] Dashboard opened`
   - Cubit emits `Loading` → shows "Loading QR Code..." with cached school name

2. **QR loads from API**
   - Cubit emits `QrLoaded(qrCode, schoolName)` → shows QR and school name

3. **User enters PIN**
   - Cubit emits `PinValidating(qrCode, schoolName)` → shows QR while validating
   - Logs: `[KIOSK] Attendance action completed (Student)`
   - Logs: `[KIOSK] Triggering dashboard refresh`

4. **Routed to student sign-in screen**
   - Navigation to `/kiosk/student-sign-in-and-sign-out`
   - Cubit may emit `PinSuccess(result)`

5. **User completes sign-in and returns**
   - Navigation: `context.go('/kiosk')`
   - Triggers `didChangeDependencies()` → calls `_loadQrCode()`
   - Logs: `[KIOSK] Dashboard resumed (didChangeDependencies)`
   - Logs: `[KIOSK] Refreshing school info`
   - Cubit emits `Loading` → shows school name with loading spinner
   - API fetch happens → Cubit emits `QrLoaded` → shows fresh QR

### Manual Refresh (Pull-to-Refresh)

User pulls down on dashboard:
- `RefreshIndicator` appears
- Calls `_refreshDashboard()`
- Logs: `[KIOSK] Refresh requested (pull-to-refresh)`
- Cubit emits `Loading` → shows "Loading QR Code..."
- API fetch happens → Cubit emits `QrLoaded` → shows fresh QR
- Spinner dismisses

---

## Verification Checklist

### Student Sign-In Flow
- [ ] Dashboard loads → QR visible, school name visible
- [ ] Enter PIN → router to student sign-in screen
- [ ] Complete student sign-in
- [ ] Return to dashboard → QR refreshes, school name visible, no cached data
- [ ] Pull down to refresh → manual refresh works, new QR loaded

### Student Sign-Out Flow
- [ ] Dashboard loads → QR visible, school name visible
- [ ] Enter PIN → route to student sign-out screen
- [ ] Complete student sign-out
- [ ] Return to dashboard → QR refreshes, school name visible, no cached data
- [ ] Pull down to refresh → manual refresh works, new QR loaded

### Staff Sign-In Flow
- [ ] Dashboard loads → QR visible, school name visible
- [ ] Enter PIN → route to staff sign-in screen
- [ ] Complete staff sign-in
- [ ] Return to dashboard → QR refreshes, school name visible, no cached data
- [ ] Pull down to refresh → manual refresh works, new QR loaded

### Staff Sign-Out Flow
- [ ] Dashboard loads → QR visible, school name visible
- [ ] Enter PIN → route to staff sign-out screen
- [ ] Complete staff sign-out
- [ ] Return to dashboard → QR refreshes, school name visible, no cached data
- [ ] Pull down to refresh → manual refresh works, new QR loaded

### Edge Cases
- [ ] Loading state shows school name (never blank)
- [ ] Error state shows school name (never blank)
- [ ] Initial state shows school name (never blank)
- [ ] Pin validating state shows school name or "School" fallback
- [ ] QR area never collapses (always has height)
- [ ] Multiple rapid refreshes don't cause issues (flag prevents it)
- [ ] App foreground/background correctly triggers refresh

### Debug Logs
- [ ] `[KIOSK] Dashboard opened` appears on screen entry
- [ ] `[KIOSK] Dashboard resumed` appears when app comes to foreground
- [ ] `[KIOSK] Dashboard resumed (didChangeDependencies)` appears on return from sub-screen
- [ ] `[KIOSK] Refreshing school info` appears during auto-refresh
- [ ] `[KIOSK] Refreshing QR` appears during any refresh
- [ ] `[KIOSK] Refresh requested (pull-to-refresh)` appears on manual pull-down

---

## Technical Details

### Why `didChangeDependencies()` Fires Reliably
- Called when a widget's dependency changes (context, inherited widgets)
- Called whenever the widget is moved/re-inserted in tree
- GoRouter's route replacement causes widget tree rebuild → triggers this callback
- More reliable than `didPushNext/didPopNext` which depend on Navigator state

### Why `RefreshIndicator` Works Here
- Wraps the BlocBuilder, so refresh calls `_refreshDashboard()`
- Which calls `loadQrCode()` on the cubit
- Which emits `Loading` → triggers UI update with loading indicator
- API response emits `QrLoaded` → dismisses indicator
- No special handling needed in cubit; it already properly handles loading states

### Why School Name Never Disappears
- Cached in `_cachedSchoolName` variable
- Updated whenever `QrLoaded` state is received
- Falls back to cached value in loading/error states
- Fallback to `'School'` if cache is empty (first load)
- `_getSchoolName()` method ensures this logic for all state types

### Why QR Area Never Collapses
- `KioskQrSectionWidget` always returns a Column with fixed layout
- `_buildLoadingState()` always shows school name + loading spinner
- Never returns `SizedBox.shrink()` or empty container
- Parent screens provide fixed height constraints
- Even during error states, the container is visible with messaging

---

## Future Improvements (Out of Scope)

1. **Periodic Auto-Refresh**: Refresh QR every 5-10 minutes to prevent expiration
2. **Optimistic Updates**: Show "Refreshing..." state during navigation back
3. **State Persistence**: Save QR in local cache for offline display
4. **Error Recovery**: Retry logic for failed API calls
5. **Animation**: Smooth transitions between states
