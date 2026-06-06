# Kiosk Dashboard Refresh Fix - Verification Checklist

## Pre-Testing Setup
- [ ] App is clean built (no stale artifacts)
- [ ] All dependencies are updated
- [ ] Device/emulator is ready with network access
- [ ] Logs can be viewed in console (adb logcat or Xcode console)
- [ ] Test school with known PIN code is available

---

## Test 1: Dashboard Initial Load
**Objective**: Verify QR and school name are always visible

**Steps**:
1. Launch app and navigate to Kiosk Dashboard screen
2. Observe initial loading state

**Expected Results**:
- [ ] School name is visible (either real name or "School" fallback)
- [ ] QR area is visible with loading spinner
- [ ] "Loading QR Code..." text appears
- [ ] No empty/blank area where QR should be
- [ ] Log appears: `[KIOSK] Dashboard opened`

**Status**: _____ (Pass/Fail)

---

## Test 2: QR Code Loads Successfully
**Objective**: Verify QR code loads and displays correctly

**Steps**:
1. Wait for QR loading to complete
2. Observe loaded QR state

**Expected Results**:
- [ ] School name remains visible
- [ ] QR code image is displayed in center of screen
- [ ] QR is scannable (visual check: clear black/white pattern)
- [ ] "Scan the QR Code" text is visible
- [ ] Loading spinner is gone
- [ ] Log appears: `[KIOSK] Refreshing QR`

**Status**: _____ (Pass/Fail)

---

## Test 3: Student Sign-In Flow - Navigation
**Objective**: Verify sign-in flow navigates correctly

**Prerequisites**: Dashboard is showing QR code

**Steps**:
1. Look at PIN pad on dashboard
2. Enter valid 4-digit PIN for student account
3. Observe navigation to student sign-in screen

**Expected Results**:
- [ ] PIN is accepted (no error)
- [ ] Router navigates to student sign-in screen
- [ ] Sign-in form loads successfully
- [ ] No crash or blank screen
- [ ] Log appears: `[KIOSK] Attendance action completed (Student)`

**Status**: _____ (Pass/Fail)

---

## Test 4: Student Sign-In Flow - Completion & Return
**Objective**: Verify dashboard refreshes after student sign-in

**Prerequisites**: On student sign-in form

**Steps**:
1. Complete student sign-in process (select students, submit form)
2. Observe navigation back to dashboard
3. Check if QR and school name are visible
4. Wait for refresh to complete

**Expected Results**:
- [ ] Sign-in completes without error
- [ ] Route returns to dashboard (`/kiosk`)
- [ ] School name is visible immediately
- [ ] QR area shows loading spinner briefly
- [ ] Fresh QR code loads and displays
- [ ] Dashboard is NOT showing stale/cached data
- [ ] Log appears: `[KIOSK] Dashboard resumed (didChangeDependencies)`
- [ ] Log appears: `[KIOSK] Refreshing school info`

**Status**: _____ (Pass/Fail)

---

## Test 5: Student Sign-Out Flow - Completion & Return
**Objective**: Verify dashboard refreshes after student sign-out

**Prerequisites**: Dashboard showing QR code, signed-in student available

**Steps**:
1. Enter PIN for student account (with signed-in students)
2. Select sign-out action (or navigate to sign-out form)
3. Complete student sign-out process
4. Observe navigation back to dashboard
5. Wait for refresh

**Expected Results**:
- [ ] Sign-out completes without error
- [ ] Route returns to dashboard
- [ ] School name is visible immediately
- [ ] QR area shows loading spinner briefly
- [ ] Fresh QR code loads and displays
- [ ] No stale/cached data displayed
- [ ] Log appears: `[KIOSK] Dashboard resumed (didChangeDependencies)`
- [ ] Log appears: `[KIOSK] Refreshing school info`

**Status**: _____ (Pass/Fail)

---

## Test 6: Staff Sign-In Flow - Completion & Return
**Objective**: Verify dashboard refreshes after staff sign-in

**Prerequisites**: Dashboard showing QR code, staff account available

**Steps**:
1. Enter PIN for staff account (signed out)
2. Observe navigation to staff sign-in form
3. Complete staff sign-in process
4. Observe navigation back to dashboard
5. Wait for refresh

**Expected Results**:
- [ ] Navigation to staff sign-in screen succeeds
- [ ] Sign-in completes without error
- [ ] Route returns to dashboard
- [ ] School name is visible immediately
- [ ] QR area shows loading spinner
- [ ] Fresh QR code loads
- [ ] No stale data displayed
- [ ] Log appears: `[KIOSK] Attendance action completed (Staff)`
- [ ] Log appears: `[KIOSK] Dashboard resumed (didChangeDependencies)`

**Status**: _____ (Pass/Fail)

---

## Test 7: Staff Sign-Out Flow - Completion & Return
**Objective**: Verify dashboard refreshes after staff sign-out

**Prerequisites**: Dashboard showing QR code, signed-in staff account available

**Steps**:
1. Enter PIN for staff account (already signed in)
2. Observe navigation to staff sign-out form
3. Complete staff sign-out process
4. Observe navigation back to dashboard
5. Wait for refresh

**Expected Results**:
- [ ] Navigation to staff sign-out screen succeeds
- [ ] Sign-out completes without error
- [ ] Route returns to dashboard
- [ ] School name is visible immediately
- [ ] QR area shows loading spinner
- [ ] Fresh QR code loads
- [ ] No stale data displayed
- [ ] Log appears: `[KIOSK] Attendance action completed (Staff)`
- [ ] Log appears: `[KIOSK] Dashboard resumed (didChangeDependencies)`

**Status**: _____ (Pass/Fail)

---

## Test 8: Pull-to-Refresh - Manual Refresh
**Objective**: Verify manual refresh works via pull gesture

**Prerequisites**: Dashboard showing QR code

**Steps**:
1. On dashboard, drag/pull down from top of screen
2. Observe refresh indicator appears
3. Wait for refresh to complete

**Expected Results**:
- [ ] Pull gesture triggers `RefreshIndicator`
- [ ] Visual indicator (spinner) appears at top
- [ ] School name remains visible
- [ ] QR area shows loading state
- [ ] Fresh QR loads from API
- [ ] Indicator dismisses automatically
- [ ] Log appears: `[KIOSK] Refresh requested (pull-to-refresh)`

**Status**: _____ (Pass/Fail)

---

## Test 9: School Name Never Blank - Loading State
**Objective**: Verify school name is always visible during loading

**Steps**:
1. Trigger a refresh (pull-to-refresh or navigate back)
2. Immediately observe the loading state

**Expected Results**:
- [ ] School name is visible while QR is loading
- [ ] Not a blank text or missing field
- [ ] Shows actual school name (not fallback "School")
- [ ] Loading spinner appears below school name
- [ ] Container is not collapsed (has visible height)

**Status**: _____ (Pass/Fail)

---

## Test 10: School Name Never Blank - Error State
**Objective**: Verify school name is shown even if QR load fails

**Prerequisites**: Network connectivity issue or API error

**Steps**:
1. Disconnect network or trigger error condition
2. Trigger a refresh
3. Observe error state

**Expected Results**:
- [ ] School name is visible in error state
- [ ] Error message appears ("Unable to load QR code")
- [ ] QR area shows placeholder with error icon
- [ ] Container is not collapsed
- [ ] User can still see which school this is for

**Status**: _____ (Pass/Fail)

---

## Test 11: QR Area Never Collapses
**Objective**: Verify QR section always maintains visible space

**Steps**:
1. Navigate through app and return to dashboard multiple times
2. Trigger various state changes (loading, error, success)
3. Observe QR area in all states

**Expected Results**:
- [ ] QR section always takes up screen space
- [ ] Never collapses to zero size (SizedBox.shrink issue fixed)
- [ ] Always shows something (school name or loading state at minimum)
- [ ] Layout is consistent across different states
- [ ] PIN pad below is never pushed off screen by QR collapsing

**Status**: _____ (Pass/Fail)

---

## Test 12: App Foreground/Background
**Objective**: Verify refresh triggers when app comes to foreground

**Steps**:
1. On dashboard with visible QR
2. Switch app to background (home button or switch app)
3. Wait 5-10 seconds
4. Switch back to this app

**Expected Results**:
- [ ] App resumes to dashboard screen
- [ ] QR area shows loading spinner
- [ ] Fresh QR loads from API
- [ ] School name remains visible
- [ ] Log appears: `[KIOSK] Dashboard resumed`

**Status**: _____ (Pass/Fail)

---

## Test 13: Multiple Rapid Refreshes
**Objective**: Verify app handles multiple refreshes gracefully

**Steps**:
1. On dashboard with visible QR
2. Pull-to-refresh multiple times in quick succession
3. Observe behavior

**Expected Results**:
- [ ] No crashes or errors
- [ ] Latest refresh completes successfully
- [ ] Flag prevents race conditions (`_isRefreshingQr` flag)
- [ ] UI remains responsive
- [ ] QR displays correctly after all refreshes

**Status**: _____ (Pass/Fail)

---

## Test 14: Debug Logs - Complete Flow
**Objective**: Verify all debug logs appear in correct sequence

**Steps**:
1. Clear console logs
2. Navigate to dashboard (from login/sign-in screen)
3. Wait for QR to load
4. Enter PIN
5. Complete attendance action
6. Return to dashboard
7. Pull-to-refresh
8. Review console logs

**Expected Logs** (in order):
- [ ] `[KIOSK] Dashboard opened`
- [ ] `[KIOSK] Dashboard refresh requested (initState)`
- [ ] `[KIOSK] Refreshing QR`
- [ ] `[KIOSK] School info loaded` (or similar)
- [ ] `[KIOSK] QR loaded` (or similar)
- [ ] `[KIOSK] Attendance action completed (Student/Staff)`
- [ ] `[KIOSK] Triggering dashboard refresh`
- [ ] `[KIOSK] Dashboard resumed (didChangeDependencies)` (on return)
- [ ] `[KIOSK] Refreshing school info`
- [ ] `[KIOSK] Refresh requested (pull-to-refresh)` (on manual refresh)

**Status**: _____ (Pass/Fail)

---

## Test 15: Edge Case - No School Name in State
**Objective**: Verify fallback handling when school name is missing

**Steps**:
1. If possible, trigger a state where schoolName is null/empty
2. Observe QR section

**Expected Results**:
- [ ] Falls back to `_cachedSchoolName` variable
- [ ] If cache is empty, shows "School" as fallback
- [ ] Never shows blank/empty text
- [ ] QR area still visible

**Status**: _____ (Pass/Fail)

---

## Summary

### Passed Tests: ____ / 15
### Failed Tests: ____ / 15

### Critical Issues (if any):
_________________________________________________________________________________
_________________________________________________________________________________
_________________________________________________________________________________

### Notes:
_________________________________________________________________________________
_________________________________________________________________________________
_________________________________________________________________________________

### Tester Name: ___________________
### Date: ___________________
### Device/Emulator: ___________________
### Android/iOS Version: ___________________
