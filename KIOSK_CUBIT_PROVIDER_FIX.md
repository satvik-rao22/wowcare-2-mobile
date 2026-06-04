# Kiosk Staff Sign-In BlocProvider Fix

## Problem

When user tapped the sign-in button on the kiosk staff sign-in form, the app showed an error and **did NOT hit the API**.

Error message displayed: Related to staff code resolution or sign-in failure

## Root Cause

The `KioskStaffSignForm` widget was trying to access `KioskAttendanceCubit` using:
```dart
final cubit = context.read<KioskAttendanceCubit>();
```

However, the cubit was **never provided in the widget tree**. The route configuration only provided `KioskDashboardCubit` but not `KioskAttendanceCubit`.

When `context.read()` fails to find the cubit, it throws a `ProviderNotFoundException`, which was caught by the try-catch and shown as a generic error. The API was never called.

## Solution

### Step 1: Import KioskAttendanceCubit in app_router.dart
```dart
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_attendance_cubit.dart';
```

### Step 2: Wrap KioskStaffSignForm with BlocProvider

**Before:**
```dart
GoRoute(
  path: 'staff-sign',
  pageBuilder: (context, state) => _fastPage(
    state,
    const KioskStaffSignForm(),  // ❌ No cubit provided!
  ),
),
```

**After:**
```dart
GoRoute(
  path: 'staff-sign',
  pageBuilder: (context, state) => _fastPage(
    state,
    BlocProvider<KioskAttendanceCubit>(  // ✅ Cubit provided!
      create: (_) => serviceLocator<KioskAttendanceCubit>(),
      child: const KioskStaffSignForm(),
    ),
  ),
),
```

### Step 3: Add Debug Logging

Added comprehensive debug logging to help identify issues:
```dart
[KioskStaffSign] _handleSignConfirmation: staffCode=..., action=SIGN_IN
[KioskStaffSign] Cubit obtained successfully
[KioskStaffSign] Calling signInStaff()...
```

If anything fails:
```dart
[KioskStaffSign] Error: <error details>
```

## Files Modified

1. **lib/src/app_router.dart**
   - Added import for KioskAttendanceCubit
   - Wrapped KioskStaffSignForm with BlocProvider

2. **lib/presentation/features/kiosk/view/kiosk_staff_sign_form.dart**
   - Added logger_service import
   - Added debug logging in _handleSignConfirmation method

## Impact

### ✅ What's Fixed
1. KioskAttendanceCubit is now available to the form
2. `context.read<KioskAttendanceCubit>()` will succeed
3. Sign-in/out methods will be called correctly
4. API calls will be made to the correct endpoints:
   - `POST /api/v1/staff-attendance-records/sign-in/self`
   - `POST /api/v1/staff-attendance-records/sign-out`

### ✅ What's Expected After Fix
1. User enters PIN on kiosk dashboard
2. PIN is verified ✓
3. Staff sign-in form is displayed ✓
4. User taps "Sign In" button
5. **API is called** ✓ (now working!)
6. Success message shown ✓
7. Redirected back to kiosk dashboard ✓

### 🔍 How to Verify
1. Check logs for: `[KioskStaffSign] Cubit obtained successfully`
2. Check logs for: `[KioskAttendance] Staff sign-in initiated`
3. Verify API is called to `/staff-attendance-records/sign-in/self`
4. No ProviderNotFoundException errors

## Testing Checklist

- [ ] Kiosk user logs in
- [ ] User enters valid 4-digit PIN
- [ ] Staff sign-in form displays correctly
- [ ] User taps "Sign In" button
- [ ] API call is made (check network logs)
- [ ] No errors displayed
- [ ] Success message shown
- [ ] User redirected to kiosk dashboard
- [ ] Logs show `[KioskStaffSign] Cubit obtained successfully`

## BlocProvider Architecture

### Widget Hierarchy
```
GoRouter
└── _fastPage()
    └── BlocProvider<KioskAttendanceCubit>  ← Provides cubit
        └── KioskStaffSignForm
            ├── BlocListener<KioskAttendanceCubit>  ← Listens to cubit
            └── context.read<KioskAttendanceCubit>()  ← Reads cubit
```

### Why This Works
- BlocProvider creates and provides the cubit to the entire subtree
- KioskStaffSignForm can now access the cubit via context.read()
- When cubit emits state changes, BlocListener receives them
- Success/error handling works correctly

## Commits

1. **81f5f59**: Fix legacy staff code resolution for KIOSK users
2. **f013eea**: Fix: Provide KioskAttendanceCubit to staff sign-in form via BlocProvider

## Related Documentation

- [KIOSK_FIX_SUMMARY.md](KIOSK_FIX_SUMMARY.md) - User details integration
- [KIOSK_STAFF_LOOKUP_FIX.md](KIOSK_STAFF_LOOKUP_FIX.md) - Staff code resolution fix
- [lib/presentation/features/kiosk/cubit/kiosk_attendance_cubit.dart](lib/presentation/features/kiosk/cubit/kiosk_attendance_cubit.dart) - Cubit implementation
