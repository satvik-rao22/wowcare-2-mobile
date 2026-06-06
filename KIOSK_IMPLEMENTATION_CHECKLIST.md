# Kiosk Student Sign-In/Sign-Out Implementation - Complete Checklist

## ✅ IMPLEMENTATION COMPLETED

### Files Created
- [x] `lib/presentation/features/kiosk/widgets/kiosk_sign_in_and_sign_out.dart` (NEW)

### Files Modified
- [x] `lib/src/app_router.dart` 
  - Added import for KioskStudentSignInAndSignOutPage
  - Registered new route: `/kiosk/student-sign-in-and-sign-out`
  
- [x] `lib/presentation/features/kiosk/utils/kiosk_access_control.dart`
  - Added `/kiosk/student-sign-in-and-sign-out` to allowedRoutes list
  
- [x] `lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart`
  - Updated `_routeGuardianStudentAttendance()` to navigate to new unified route
  - Added action determination logic (sign-in, sign-out, or selection)

---

## IMPLEMENTATION SUMMARY

### What Changed

**Before:**
```
Guardian PIN Verification
  ↓
Navigate to /dashboard/student-sign-in-out-selection
  ↓
[LEAVES KIOSK CONTEXT]
```

**After:**
```
Guardian PIN Verification
  ↓
Navigate to /kiosk/student-sign-in-and-sign-out
  ↓
[STAYS IN KIOSK CONTEXT]
  ↓
Show appropriate screen (selection, sign-in, or sign-out)
  ↓
Success → Return to /kiosk
```

### Key Features

1. **Unified Flow**: One page handles selection, sign-in, and sign-out
2. **Business Logic Reuse**: Uses existing StudentSignInForm, StudentSignOutForm, StudentSignInOutSelectionScreen
3. **Smart Action Routing**: Automatically determines which screen to show
   - Both signed-in & signed-out students → Show selection
   - Only signed-out → Show sign-in form
   - Only signed-in → Show sign-out form
4. **Kiosk Context**: Never leaves `/kiosk/*` path during flow
5. **Success Handling**: Shows success message, returns to kiosk dashboard

---

## QUICK START TESTING

### Prerequisite: Rebuild App
```bash
# Clean build to ensure all changes are loaded
flutter clean
flutter pub get
flutter run --release
```

### Test 1: Happy Path - Guardian with Both States
```
1. Start kiosk app
2. Get a guardian PIN that has:
   - Some students SIGNED IN
   - Some students SIGNED OUT
3. Enter PIN
4. ✓ Should show selection screen (tap "Sign In" or "Sign Out")
5. ✓ Should show appropriate form
6. ✓ Submit should succeed
7. ✓ Should return to kiosk (NOT dashboard)
```

### Test 2: Happy Path - Only Signed-Out Students
```
1. Get a guardian PIN with ALL students SIGNED OUT
2. Enter PIN
3. ✓ Should show sign-in form directly (no selection)
4. ✓ Submit should succeed
5. ✓ Should return to kiosk
```

### Test 3: Happy Path - Only Signed-In Students
```
1. Get a guardian PIN with ALL students SIGNED IN
2. Enter PIN
3. ✓ Should show sign-out form directly (no selection)
4. ✓ Submit should succeed
5. ✓ Should return to kiosk
```

### Test 4: Back Navigation
```
1. On selection/form screen
2. Tap system back button (or swipe back)
3. ✓ Should navigate to /kiosk (not previous form screen)
4. ✓ Should NOT get stuck in loop
```

### Test 5: Error Handling
```
1. Try entering PIN for guardian with NO students
2. ✓ Should show error "No students found"
3. ✓ Should stay on kiosk dashboard
```

---

## DETAILED TESTING MATRIX

### Happy Path Tests

#### Test H1: Guardian - Selection Screen (Both Sign-In & Sign-Out)
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Enter guardian PIN | PIN verified | |
| 2 | View screen | Selection screen appears | |
| 3 | Tap "Sign In" | Sign-in form appears | |
| 4 | Select students | Students appear in list | |
| 5 | Submit | API success | |
| 6 | View message | "Signed in successfully" | |
| 7 | Navigate | Returns to /kiosk | |

#### Test H2: Guardian - Sign-In Only
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Enter guardian PIN | PIN verified | |
| 2 | View screen | Sign-in form appears (no selection) | |
| 3 | List shows | Only signed-out students | |
| 4 | Select & submit | API success | |
| 5 | Result | Returns to /kiosk | |

#### Test H3: Guardian - Sign-Out Only
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Enter guardian PIN | PIN verified | |
| 2 | View screen | Sign-out form appears (no selection) | |
| 3 | List shows | Only signed-in students | |
| 4 | Select & submit | API success | |
| 5 | Result | Returns to /kiosk | |

#### Test H4: Sibling Selection
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Sign-in with siblings | Selection screen/form loads | |
| 2 | See siblings | All children shown | |
| 3 | Multi-select | Can select multiple | |
| 4 | Submit | Only selected sign in | |
| 5 | Result | Success message | |

### Edge Case Tests

#### Test E1: No Students Found
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Enter PIN (no students) | PIN verified | |
| 2 | View screen | Error message shown | |
| 3 | Message | "No students found" | |
| 4 | Navigation | Stays on /kiosk | |

#### Test E2: Guardian Code Missing
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | PIN verification | Result has empty guardianCode | |
| 2 | View screen | Error message shown | |
| 3 | Message | "Guardian code not found" | |
| 4 | Navigation | Stays on /kiosk | |

#### Test E3: Back Button in Selection Screen
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Show selection | Screen visible | |
| 2 | Tap back | Navigation triggered | |
| 3 | Result | Goes to /kiosk | |
| 4 | State | PIN state reset | |

#### Test E4: Back Button in Sign-In Form
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Show sign-in | Form visible | |
| 2 | Tap back | Navigation triggered | |
| 3 | Result | Goes to /kiosk (not selection) | |
| 4 | Logs | Shows "Back button pressed" | |

#### Test E5: Network Error During Submit
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Sign-in screen | Form shown | |
| 2 | Submit (no network) | API fails | |
| 3 | Error shown | Error message displayed | |
| 4 | Form state | Stays on form (doesn't return) | |
| 5 | Can retry | Back button available | |

### Integration Tests

#### Test I1: Staff Still Works
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Enter staff PIN | PIN verified | |
| 2 | Navigate | Goes to /dashboard/staff-sign-in-form | |
| 3 | Sign-in | Works normally | |
| 4 | Result | Returns to normal flow (not kiosk) | |

#### Test I2: Multiple PINs in Sequence
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Enter PIN 1 | Success, return to /kiosk | |
| 2 | Enter PIN 2 | Success, return to /kiosk | |
| 3 | Repeat 5x | All succeed, no state corruption | |
| 4 | Memory | No leaks, smooth operation | |

#### Test I3: Fast Navigation Sequence
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Enter PIN | Show screen | |
| 2 | Immediately tap back | Back works | |
| 3 | Enter new PIN | Works correctly | |
| 4 | Result | No race conditions | |

#### Test I4: Route Guard Verification
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Kiosk inactive | Try access /kiosk/student-... | |
| 2 | Result | Redirects to /kiosk or /sign-in | |
| 3 | Kiosk active | Can access route | |
| 4 | Route guard | Validates correctly | |

### Regression Tests

#### Test R1: Dashboard Student Sign-In (Non-Kiosk)
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Login as parent | Normal dashboard | |
| 2 | Access attendance | Attendance tab works | |
| 3 | Start sign-in | Uses OLD flow | |
| 4 | Complete | Works unchanged | |

#### Test R2: Kiosk Staff (Unchanged)
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Kiosk staff PIN | Verified | |
| 2 | Navigate | Staff sign-in form | |
| 3 | Complete | Works as before | |

#### Test R3: Kiosk Legacy Routes (Compatibility)
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Deep-link to old | /dashboard/student-... | |
| 2 | Route loads | Works if kiosk active | |
| 3 | Navigation | Backward compatible | |

#### Test R4: Old Dashboard Routes
| Step | Action | Expected | Status |
|------|--------|----------|--------|
| 1 | Non-kiosk user | Can access /dashboard/* | |
| 2 | Flow works | No changes to dashboard | |

---

## LOG VERIFICATION

### Expected Logs During Happy Path

```
[Kiosk] PIN verification success: persona=guardian
[KioskAccess] Cache updated: kiosk_mode=true, persona=guardian
[KioskAccess] Route check: path=/kiosk/student-sign-in-and-sign-out, allowed=true
[Kiosk] Routing to unified student-sign-in-and-sign-out page: action=selection
[Kiosk] KioskStudentSignInAndSignOut.initState: action=selection, signedIn=2, signedOut=3
[Kiosk] Building screen: action=selection
[Kiosk] Sign-in/out completed: Students signed in successfully
[Kiosk] Back button pressed, returning to kiosk dashboard
[GoRouter] Navigating to: /kiosk
```

### Expected Logs During Error

```
[Kiosk] _routeGuardianStudentAttendance: guardianCode=GUA_123, signedInStudents=0, signedOutStudents=0
[Kiosk] No students found error
```

---

## ROLLBACK PLAN

If issues occur, the old routes are still available:

### Keep Old Routes Working (Current Setup)
- Old routes: `/dashboard/student-selection-sign-in-form`, etc. still exist
- Kiosk can still navigate to them if needed
- Can switch back by updating `_routeGuardianStudentAttendance()` method

### Quick Rollback Steps
```dart
// In kiosk_dashboard_screen.dart, line ~290
// Change this:
GoRouter.of(context).go(
  '/kiosk/student-sign-in-and-sign-out',
  // ...
);

// Back to this:
GoRouter.of(context).go(
  '/dashboard/student-sign-in-out-selection',
  // ...
);
```

---

## VERIFICATION COMMANDS

```bash
# 1. Check imports
grep "KioskStudentSignInAndSignOutPage" lib/src/app_router.dart

# 2. Check route registration
grep -n "student-sign-in-and-sign-out" lib/src/app_router.dart

# 3. Check whitelist
grep -n "student-sign-in-and-sign-out" lib/presentation/features/kiosk/utils/kiosk_access_control.dart

# 4. Check navigation
grep -n "/kiosk/student-sign-in-and-sign-out" lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart

# 5. Build and run
flutter clean && flutter pub get && flutter run --release
```

---

## SUCCESS CRITERIA

✅ All 5 main tests pass  
✅ No redirect loops  
✅ User stays in /kiosk context  
✅ Returns to /kiosk after success  
✅ Back button works correctly  
✅ Error messages show  
✅ Staff flow unchanged  
✅ Dashboard flow unchanged  
✅ No memory leaks  
✅ Logs are clear and helpful  

---

## NEXT STEPS (Optional)

### Phase 2: Deprecate Old Routes
Once stable for 2+ weeks, deprecate old dashboard routes:
```dart
// Add warning log when old routes accessed from kiosk
AppLogger.w('[Kiosk] Legacy route accessed, will be removed in v2.0');
```

### Phase 3: Clean Up
Remove old routes entirely if no usage found in analytics

---

## SUPPORT

**If navigation still redirects to /kiosk:**
1. Check logs for: `[KioskAccess] Route check`
2. Verify route registered: `grep student-sign-in-and-sign-out lib/src/app_router.dart`
3. Verify whitelisted: `grep student-sign-in-and-sign-out lib/presentation/features/kiosk/utils/kiosk_access_control.dart`
4. Check imports: `grep KioskStudentSignInAndSignOutPage lib/src/app_router.dart`

**If page doesn't show selection screen:**
1. Check `action` parameter is passed correctly
2. Verify StudentSignInOutSelectionScreen is imported
3. Check logs for: `[Kiosk] Building screen: action=`

**If returning to dashboard instead of kiosk:**
1. Check `_handleSuccess()` method navigation
2. Verify `context.go('/kiosk')` is correct
3. Check logs for: `[Kiosk] Returning to kiosk dashboard`

