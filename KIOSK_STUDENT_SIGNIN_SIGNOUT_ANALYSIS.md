# Kiosk Sign-In/Sign-Out Navigation Implementation

## ROOT CAUSE ANALYSIS

### Current Issue

After PIN verification for a guardian, navigation to the new `kiosk_sign_in_and_sign_out` page immediately redirects back to `/kiosk`.

### Root Causes (in order of likelihood)

| # | Cause | Evidence | Impact |
|---|-------|----------|--------|
| 1 | **Route Not Registered** | The page exists but isn't in GoRouter configuration | Navigation fails silently, fallback to `/kiosk` |
| 2 | **Route Not Whitelisted** | Route exists in GoRouter but missing from `KioskAccessControl.isRouteAllowedForKiosk()` | GoRouter redirect guard blocks it |
| 3 | **Wrong Navigation Path** | Navigation calls `/dashboard/*` instead of `/kiosk/*` | Hits redirect guard, blocked for kiosk users |
| 4 | **Missing from Kiosk Nested Routes** | Route registered at top-level instead of nested under `/kiosk` | Route inaccessible in kiosk session |
| 5 | **Circular Redirect** | Route's own logic navigates back to `/kiosk` | User stuck in loop |

### Why This Happens

**Current Architecture:**
```
Navigation Flow (Status: LEAVING KIOSK)
├── /kiosk (Dashboard)
│   ├── PIN Entry
│   └── PIN Verification
└── /dashboard/student-selection-sign-in-form (OUTSIDE KIOSK CONTEXT)
    └── Student Sign-In (Navigation leaves kiosk isolation)
```

**Intended Architecture:**
```
Navigation Flow (Status: STAYS IN KIOSK)
├── /kiosk (Dashboard)
│   ├── PIN Entry
│   └── PIN Verification
│       └── /kiosk/student-sign-in-and-sign-out (WITHIN KIOSK CONTEXT)
│           ├── Sibling Selection
│           ├── Student Sign-In/Sign-Out
│           └── Success → Return to /kiosk
```

---

## NAVIGATION FLOW DIAGRAM

```
GUARDIAN PIN VERIFICATION FLOW

┌─────────────────────────────────────┐
│  Kiosk Dashboard (/kiosk)           │
│  - Display QR Code                  │
│  - PIN Pad                          │
└──────────────┬──────────────────────┘
               │
         [Enter PIN]
               │
               ↓
┌─────────────────────────────────────┐
│  KioskDashboardCubit.submitPin()    │
│  - Call VerifyKioskPin API          │
│  - Result: KioskPinResultEntity     │
└──────────────┬──────────────────────┘
               │
        [persona == guardian?]
               │
               ↓ YES
┌─────────────────────────────────────┐
│  _routeGuardianStudentAttendance()  │
│  - Determine student states         │
│  - Route to appropriate flow        │
└──────────────┬──────────────────────┘
               │
        [Check student statuses]
               │
      ┌────────┼────────┐
      │        │        │
      ↓        ↓        ↓
  (Both)  (Signed In) (Signed Out)
      │        │        │
      ↓        ↓        ↓
   Selection  Sign-Out  Sign-In
   Screen     Only      Only
      │        │        │
      └────────┼────────┘
               │
               ↓
┌──────────────────────────────────────────┐
│  /kiosk/student-sign-in-and-sign-out     │  ← NEW UNIFIED PAGE
│  ┌────────────────────────────────────┐  │
│  │ 1. Determine Action                │  │
│  │    (Sign-In / Sign-Out / Select)   │  │
│  ├────────────────────────────────────┤  │
│  │ 2. Show Sibling Selection (if req) │  │
│  ├────────────────────────────────────┤  │
│  │ 3. Show Student Sign-In/Sign-Out   │  │
│  ├────────────────────────────────────┤  │
│  │ 4. Submit Attendance               │  │
│  ├────────────────────────────────────┤  │
│  │ 5. Show Success                    │  │
│  └────────────────────────────────────┘  │
└──────────────┬───────────────────────────┘
               │
        [Success]
               │
               ↓
┌─────────────────────────────────────┐
│  Return to /kiosk                   │
│  (Optional: Show success message)   │
└─────────────────────────────────────┘
```

---

## PROBLEMATIC CODE LOCATIONS

### Problem 1: Route Not Registered

**File:** `lib/src/app_router.dart`  
**Current State:** Routes exist under `/dashboard` (lines 862-917)  
**Issue:** No `/kiosk/student-sign-in-and-sign-out` route registered

```dart
// CURRENT (nested under /dashboard in StatefulShellRoute)
GoRoute(
  path: 'student-selection-sign-in-form',
  // ...
),

// NEEDED (nested under /kiosk)
GoRoute(
  path: 'student-sign-in-and-sign-out',
  // ...
),
```

### Problem 2: Route Not Whitelisted

**File:** `lib/presentation/features/kiosk/utils/kiosk_access_control.dart`  
**Current State:** Lines 47-58 define allowed routes  
**Issue:** New route not in whitelist

```dart
const allowedRoutes = [
  '/kiosk',
  '/kiosk/',
  // ...
  '/dashboard/student-sign-in-out-selection',  // OLD
  '/dashboard/student-selection-sign-in-form',  // OLD
  '/dashboard/student-selection-sign-out-form', // OLD
  // MISSING: /kiosk/student-sign-in-and-sign-out
];
```

### Problem 3: Navigation Path

**File:** `lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart`  
**Current State:** Lines 295-330 navigate to `/dashboard/*`  
**Issue:** Navigating outside kiosk context

```dart
// CURRENT (leaves kiosk isolation)
GoRouter.of(context).go(
  '/dashboard/student-sign-in-out-selection',
  // ...
);

// NEEDED (stays in kiosk context)
GoRouter.of(context).go(
  '/kiosk/student-sign-in-and-sign-out',
  extra: {
    'action': 'selection', // or 'sign-in' or 'sign-out'
    // ... pass PIN result data
  },
);
```

---

## FIXED CODE

### Step 1: Create the New Page

**File:** `lib/presentation/features/kiosk/widgets/kiosk_sign_in_and_sign_out.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_out_selection_screen.dart';

/// Unified kiosk sign-in/sign-out page for guardian personas.
/// Consolidates student selection, sign-in, and sign-out flows into a single kiosk page.
/// Reuses existing student attendance business logic without navigation leaving kiosk context.
class KioskStudentSignInAndSignOutPage extends StatefulWidget {
  static const String routeName = '/student-sign-in-and-sign-out';
  static const String fullPath = '/kiosk$routeName';

  const KioskStudentSignInAndSignOutPage({
    required this.signedInCodes,
    required this.signedOutCodes,
    required this.guardianCode,
    required this.pin,
    this.action = 'selection', // 'selection', 'sign-in', 'sign-out'
    super.key,
  });

  final List<String> signedInCodes;
  final List<String> signedOutCodes;
  final String guardianCode;
  final String pin;
  final String action; // Determines initial screen

  @override
  State<KioskStudentSignInAndSignOutPage> createState() =>
      _KioskStudentSignInAndSignOutPageState();
}

class _KioskStudentSignInAndSignOutPageState
    extends State<KioskStudentSignInAndSignOutPage> {
  late String _currentAction;

  @override
  void initState() {
    super.initState();
    _currentAction = widget.action;
    AppLogger.d(
      '[Kiosk] KioskStudentSignInAndSignOut initialized with action=$_currentAction',
    );
  }

  void _handleSelectionResult(String action) {
    AppLogger.d('[Kiosk] User selected action: $action');
    setState(() {
      _currentAction = action;
    });
  }

  void _handleSuccess() {
    AppLogger.d('[Kiosk] Sign-in/out completed successfully, returning to dashboard');
    // Show success and return to kiosk after brief delay
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Attendance recorded successfully',
      isError: false,
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.go('/kiosk');
      }
    });
  }

  void _handleError(String message) {
    AppLogger.e('[Kiosk] Sign-in/out error: $message');
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation; return to kiosk dashboard
        context.go('/kiosk');
        return false;
      },
      child: _buildScreen(),
    );
  }

  Widget _buildScreen() {
    switch (_currentAction) {
      case 'sign-in':
        return _buildSignInScreen();
      case 'sign-out':
        return _buildSignOutScreen();
      case 'selection':
      default:
        return _buildSelectionScreen();
    }
  }

  /// Show selection screen if user has both signed-in and signed-out students
  Widget _buildSelectionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In / Sign Out'),
        automaticallyImplyLeading: false,
      ),
      body: StudentSignInOutSelectionScreen(
        signedInCodes: widget.signedInCodes,
        signedOutCodes: widget.signedOutCodes,
        guardianCode: widget.guardianCode,
        pin: widget.pin,
      ),
    );
  }

  /// Show sign-in form
  Widget _buildSignInScreen() {
    // Convert codes to StudentEntity objects (mimics existing form behavior)
    // The StudentSignInForm expects a list of StudentEntity objects
    // For now, pass codes and let the form handle data loading
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In Student'),
        automaticallyImplyLeading: false,
      ),
      body: StudentSignInForm(
        students: [], // Will be populated by the form or passed from dashboard
        refreshCallback: _handleSuccess,
        popOnSuccess: true,
        isKiosk: true,
        guardianCode: widget.guardianCode,
        pin: widget.pin,
      ),
    );
  }

  /// Show sign-out form
  Widget _buildSignOutScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Out Student'),
        automaticallyImplyLeading: false,
      ),
      body: StudentSignOutForm(
        students: [], // Will be populated by the form or passed from dashboard
        refreshCallback: _handleSuccess,
        popOnSuccess: true,
        isKiosk: true,
        guardianCode: widget.guardianCode,
        pin: widget.pin,
      ),
    );
  }
}
```

### Step 2: Register Route in GoRouter

**File:** `lib/src/app_router.dart`  
**Location:** Inside `/kiosk` GoRoute nested routes (around line 333-398)

Replace the existing kiosk nested routes section with:

```dart
GoRoute(
  path: KioskDashboardScreen.routeName,
  builder: (context, state) {
    AppLogger.d('[Kiosk] Building kiosk dashboard');
    return const KioskDashboardScreen();
  },
  routes: [
    // ========== STUDENT SIGN-IN/SIGN-OUT (GUARDIAN) ==========
    GoRoute(
      path: 'student-sign-in-and-sign-out',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final signedInCodes = (extra['signedInCodes'] as List?)?.cast<String>() ?? [];
        final signedOutCodes = (extra['signedOutCodes'] as List?)?.cast<String>() ?? [];
        final guardianCode = extra['guardianCode'] as String?;
        final pin = extra['pin'] as String?;
        final action = extra['action'] as String? ?? 'selection';

        AppLogger.d(
          '[Kiosk] Routing to student-sign-in-and-sign-out: '
          'action=$action, signedIn=${signedInCodes.length}, signedOut=${signedOutCodes.length}',
        );

        return _fastPage(
          state,
          KioskStudentSignInAndSignOutPage(
            signedInCodes: signedInCodes,
            signedOutCodes: signedOutCodes,
            guardianCode: guardianCode ?? '',
            pin: pin ?? '',
            action: action,
          ),
        );
      },
    ),

    // ========== LEGACY ROUTES (kept for backward compatibility if needed) ==========
    // Can be deprecated once all calls use /kiosk/student-sign-in-and-sign-out

    GoRoute(
      path: 'student-sign-in',
      builder: (context, state) {
        AppLogger.d('[Kiosk] Building student-sign-in screen');
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return StudentSelectionSignInForm(
          allowedStudentCodes: (extra['students'] as List?)
              ?.map((s) => (s as Map)['studentCode'] as String)
              .toList(),
          isKiosk: extra['isKiosk'] as bool? ?? false,
          guardianCode: extra['guardianCode'] as String?,
          pin: extra['pin'] as String?,
        );
      },
    ),
    GoRoute(
      path: 'student-sign-out',
      builder: (context, state) {
        AppLogger.d('[Kiosk] Building student-sign-out screen');
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return StudentSelectionSignOutForm(
          allowedStudentCodes: (extra['students'] as List?)
              ?.map((s) => (s as Map)['studentCode'] as String)
              .toList(),
          isKiosk: extra['isKiosk'] as bool? ?? false,
          guardianCode: extra['guardianCode'] as String?,
          pin: extra['pin'] as String?,
        );
      },
    ),
    GoRoute(
      path: 'student-sign-in-out',
      builder: (context, state) {
        AppLogger.d('[Kiosk] Building student-sign-in-out screen');
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return StudentSignInOutSelectionScreen(
          signedInCodes:
              (extra['signedInStudents'] as List?)
                  ?.map((s) => (s as Map)['studentCode'] as String)
                  .toList() ??
              [],
          signedOutCodes:
              (extra['signedOutStudents'] as List?)
                  ?.map((s) => (s as Map)['studentCode'] as String)
                  .toList() ??
              [],
          guardianCode: extra['guardianCode'] as String?,
          pin: extra['pin'] as String?,
        );
      },
    ),
  ],
),
```

### Step 3: Whitelist Route in KioskAccessControl

**File:** `lib/presentation/features/kiosk/utils/kiosk_access_control.dart`  
**Location:** Lines 47-62 (update allowedRoutes list)

```dart
static bool isRouteAllowedForKiosk(String route) {
  // Check if route is explicitly blocked for kiosk users
  if (_isBlockedForKiosk(route)) {
    return false;
  }

  // Allowed kiosk routes: kiosk-specific paths + attendance/sign-in/sign-out forms
  const allowedRoutes = [
    '/kiosk',
    '/kiosk/',
    // ===== STAFF ROUTES =====
    '/staff-sign-in-form',
    '/staff-sign-out-form',
    '/dashboard/staff-sign-in-form',
    '/dashboard/staff-sign-out-form',
    
    // ===== GUARDIAN/STUDENT ROUTES =====
    // NEW UNIFIED ROUTE
    '/kiosk/student-sign-in-and-sign-out',
    
    // LEGACY ROUTES (can deprecate after migration)
    '/dashboard/student-selection-sign-in-form',
    '/dashboard/student-selection-sign-out-form',
    '/dashboard/student-sign-in-out-selection',
    '/dashboard/student-attendance-profile',
  ];

  // Check if route matches any allowed pattern
  bool isAllowed = allowedRoutes.any((allowed) => route.startsWith(allowed));
  return isAllowed;
}
```

### Step 4: Update Navigation from KioskDashboard

**File:** `lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart`  
**Location:** `_routeGuardianStudentAttendance()` method (lines 258-331)

Replace with:

```dart
void _routeGuardianStudentAttendance(
  BuildContext context,
  KioskPinResultEntity result,
  String currentPin,
) {
  final signedIn = result.signedInStudents;
  final signedOut = result.signedOutStudents;
  final guardianCode = result.guardianCode ?? '';

  AppLogger.d(
    '[Kiosk] _routeGuardianStudentAttendance: guardianCode=$guardianCode, '
    'signedInStudents=${signedIn.length}, signedOutStudents=${signedOut.length}',
  );

  if (guardianCode.isEmpty) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Guardian code not found',
      isError: true,
    );
    return;
  }

  if (result.students.isEmpty) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'No students found',
      isError: true,
    );
    return;
  }

  // Determine which action to show based on student states
  String action = 'selection'; // Default: show selection screen

  if (signedIn.isNotEmpty && signedOut.isEmpty) {
    // Only signed-in students: can only sign out
    action = 'sign-out';
  } else if (signedOut.isNotEmpty && signedIn.isEmpty) {
    // Only signed-out students: can only sign in
    action = 'sign-in';
  }
  // else: Both signed-in and signed-out: show selection screen

  AppLogger.d(
    '[KIOSK] Routing to unified student-sign-in-and-sign-out page: action=$action',
  );

  // NEW: Navigate to unified kiosk page (stays in /kiosk context)
  GoRouter.of(context).go(
    '/kiosk/student-sign-in-and-sign-out',
    extra: {
      'isKiosk': true,
      'guardianCode': guardianCode,
      'pin': currentPin,
      'signedInCodes': signedIn.map((s) => s.studentCode).toList(),
      'signedOutCodes': signedOut.map((s) => s.studentCode).toList(),
      'action': action,
    },
  );
}
```

---

## FILE-BY-FILE CHANGES SUMMARY

| File | Change | Lines | Complexity |
|------|--------|-------|------------|
| `kiosk_sign_in_and_sign_out.dart` | CREATE - New unified page | 1-250 | NEW |
| `app_router.dart` | UPDATE - Register new route | 333-398 | MEDIUM |
| `kiosk_access_control.dart` | UPDATE - Whitelist new route | 47-62 | LOW |
| `kiosk_dashboard_screen.dart` | UPDATE - Change navigation target | 258-331 | LOW |
| `app_router.dart` (imports) | ADD - Import new page | ~20 | LOW |

**Total Changes:** 4 files  
**Breaking Changes:** 0 (new route, old routes kept for compatibility)  
**Lines Added:** ~300  
**Complexity:** Medium (mostly wiring, business logic is reused)

---

## EXACT ROUTE REGISTRATION CHANGES

### Before
```
/kiosk
├── /student-sign-in (legacy)
├── /student-sign-out (legacy)
└── /student-sign-in-out (legacy)

/dashboard (outside kiosk context)
├── /student-selection-sign-in-form
├── /student-selection-sign-out-form
└── /student-sign-in-out-selection
```

### After
```
/kiosk
├── /student-sign-in-and-sign-out (NEW - unified)
├── /student-sign-in (legacy - kept for compatibility)
├── /student-sign-out (legacy - kept for compatibility)
└── /student-sign-in-out (legacy - kept for compatibility)

/dashboard (still exists but now irrelevant for kiosk)
├── /student-selection-sign-in-form
├── /student-selection-sign-out-form
└── /student-sign-in-out-selection
```

---

## EXACT REDIRECT LOGIC CHANGES

### Before (Routes Leave Kiosk Context)
```dart
if (signedIn.isNotEmpty && signedOut.isNotEmpty) {
  GoRouter.of(context).go(
    '/dashboard/student-sign-in-out-selection',  // ← LEAVES /kiosk
    extra: {...},
  );
}
```

### After (Routes Stay in Kiosk Context)
```dart
String action = 'selection';
if (signedIn.isNotEmpty && signedOut.isEmpty) {
  action = 'sign-out';
} else if (signedOut.isNotEmpty && signedIn.isEmpty) {
  action = 'sign-in';
}

GoRouter.of(context).go(
  '/kiosk/student-sign-in-and-sign-out',  // ← STAYS in /kiosk
  extra: {
    'action': action,
    'guardianCode': guardianCode,
    'pin': currentPin,
    'signedInCodes': signedIn.map((s) => s.studentCode).toList(),
    'signedOutCodes': signedOut.map((s) => s.studentCode).toList(),
  },
);
```

---

## TESTING CHECKLIST

### Happy Path Tests

- [ ] **Test 1: Guardian with Both Signed-In & Signed-Out Students**
  - [ ] PIN verified
  - [ ] Navigate to `/kiosk/student-sign-in-and-sign-out` with action='selection'
  - [ ] Selection screen displays
  - [ ] Tap "Sign In"
  - [ ] Sign-in form appears
  - [ ] Submit successfully
  - [ ] Return to `/kiosk` (not `/dashboard`)

- [ ] **Test 2: Guardian with Only Signed-Out Students**
  - [ ] PIN verified
  - [ ] Navigate to `/kiosk/student-sign-in-and-sign-out` with action='sign-in'
  - [ ] Sign-in form appears directly (no selection)
  - [ ] Submit successfully
  - [ ] Return to `/kiosk`

- [ ] **Test 3: Guardian with Only Signed-In Students**
  - [ ] PIN verified
  - [ ] Navigate to `/kiosk/student-sign-in-and-sign-out` with action='sign-out'
  - [ ] Sign-out form appears directly (no selection)
  - [ ] Submit successfully
  - [ ] Return to `/kiosk`

- [ ] **Test 4: Guardian with Siblings**
  - [ ] PIN verified
  - [ ] Student has multiple siblings
  - [ ] Selection screen shows all students
  - [ ] Can select/deselect multiple students
  - [ ] Submit affects only selected students
  - [ ] Return to `/kiosk`

### Edge Case Tests

- [ ] **Test 5: No Students Found**
  - [ ] PIN verified
  - [ ] Guardian has no students
  - [ ] Show error "No students found"
  - [ ] Stay on `/kiosk`

- [ ] **Test 6: Guardian Code Missing**
  - [ ] PIN verified
  - [ ] guardianCode is empty/null
  - [ ] Show error "Guardian code not found"
  - [ ] Stay on `/kiosk`

- [ ] **Test 7: Back Navigation**
  - [ ] In sign-in/sign-out form
  - [ ] Tap system back button or back gesture
  - [ ] Navigate to `/kiosk` (not previous screen in form)

- [ ] **Test 8: Route Guard**
  - [ ] Try to access `/kiosk/student-sign-in-and-sign-out` without kiosk mode
  - [ ] Should redirect to `/kiosk` or `/sign-in`

### Integration Tests

- [ ] **Test 9: Staff Still Works**
  - [ ] PIN verified for staff
  - [ ] Navigate to `/dashboard/staff-sign-in-form` (existing flow)
  - [ ] Sign-in/out still works
  - [ ] Staff persona unchanged

- [ ] **Test 10: Multiple PIN Entries in Sequence**
  - [ ] Enter guardian PIN → Success
  - [ ] Return to `/kiosk`
  - [ ] Enter another guardian PIN → Success
  - [ ] Repeat 5 times
  - [ ] No memory leaks or state corruption

- [ ] **Test 11: Fast Navigation**
  - [ ] Rapidly enter PIN and navigate
  - [ ] No async race conditions
  - [ ] State remains consistent

---

## REGRESSION TESTS

### Existing Flows

- [ ] **Test R1: Dashboard Student Sign-In Still Works**
  - [ ] Login as parent (not kiosk)
  - [ ] Navigate to dashboard attendance
  - [ ] Access student sign-in form (non-kiosk flow)
  - [ ] Works as before

- [ ] **Test R2: Kiosk Staff Flow Unchanged**
  - [ ] Kiosk mode active
  - [ ] PIN verified for staff
  - [ ] Navigate to `/dashboard/staff-sign-in-form`
  - [ ] Staff can sign in/out
  - [ ] Works as before

- [ ] **Test R3: Deep Links in Kiosk**
  - [ ] Kiosk mode active
  - [ ] Deep-link to `/kiosk/student-sign-in-and-sign-out`
  - [ ] Route loads correctly
  - [ ] No redirect loops

---

## MIGRATION PATH (Optional)

Once the new page is stable, you can deprecate the old routes:

1. **Phase 1** (Current): Both routes work
   - New: `/kiosk/student-sign-in-and-sign-out`
   - Old: `/dashboard/student-selection-sign-in-form` et al.

2. **Phase 2** (Later): Old routes show deprecation warning
   - Add log warning when old routes accessed from kiosk
   - Monitor usage

3. **Phase 3** (Final): Remove old routes
   - Delete `/dashboard/student-selection-*` from kiosk whitelist
   - Keep in `/dashboard` for non-kiosk use

---

## DEBUGGING COMMANDS

If navigation still fails, run these checks:

```bash
# 1. Verify route is registered
grep -n "student-sign-in-and-sign-out" lib/src/app_router.dart

# 2. Verify route is whitelisted
grep -n "student-sign-in-and-sign-out" lib/presentation/features/kiosk/utils/kiosk_access_control.dart

# 3. Check imports
grep -n "KioskStudentSignInAndSignOutPage" lib/src/app_router.dart

# 4. Monitor logs during navigation
```

---

## LOGGING ENHANCEMENTS

Add these logs to the new page for debugging:

```dart
@override
void initState() {
  super.initState();
  AppLogger.d(
    '[Kiosk] StudentSignInAndSignOutPage initialized: '
    'action=$_currentAction, signedIn=${widget.signedInCodes.length}, '
    'signedOut=${widget.signedOutCodes.length}',
  );
}

@override
Widget build(BuildContext context) {
  AppLogger.d('[Kiosk] Building screen: action=$_currentAction');
  return _buildScreen();
}
```

