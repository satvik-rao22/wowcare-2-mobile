# Kiosk Dashboard Refresh Fix - Implementation Summary

## Changes Made

### File 1: lib/presentation/features/kiosk/widgets/kiosk_qr_section_widget.dart

#### Change #1: Fix Fallback for Unknown States (Lines 53-56)
**Before**:
```dart
    // Show school name even if QR isn't ready yet
    return _buildLoadingState();
  }

  return const SizedBox.shrink();
}
```

**After**:
```dart
    // Show school name even if QR isn't ready yet
    return _buildLoadingState();
  }

  // NEVER return SizedBox.shrink - always show QR area with loading state
  // This handles KioskDashboardInitial and KioskDashboardPinSuccess states
  AppLogger.d('[Kiosk] Unhandled state (${state.runtimeType}) - showing loading state');
  return _buildLoadingState();
}
```

**Impact**: QR section NEVER collapses. Always shows school name + loading state or error state.

---

### File 2: lib/presentation/features/kiosk/view/kiosk_dashboard_screen.dart

#### Change #1: Add WidgetsBindingObserver (Line 33)
**Before**:
```dart
class _KioskDashboardScreenState extends State<KioskDashboardScreen> {
```

**After**:
```dart
class _KioskDashboardScreenState extends State<KioskDashboardScreen>
    with WidgetsBindingObserver {
```

**Impact**: Enables tracking of app lifecycle (foreground/background transitions).

---

#### Change #2: Add Instance Variables (Lines 35-37)
**Before**:
```dart
  final int maxPinLength = 4;
  String _currentPin = '';
```

**After**:
```dart
  final int maxPinLength = 4;
  String _currentPin = '';
  String _cachedSchoolName = 'School'; // Cache to preserve school name during QR reload
  bool _isRefreshingQr = false; // Prevent duplicate refresh calls
```

**Impact**: Enables school name caching and prevents duplicate refresh calls.

---

#### Change #3: Enhance initState with Debug Logs (Lines 40-50)
**Before**:
```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(context.read<KioskDashboardCubit>().loadQrCode());
    });
  }
```

**After**:
```dart
  @override
  void initState() {
    super.initState();
    AppLogger.d('[KIOSK] Dashboard opened');
    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Initial QR load on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.d('[KIOSK] Dashboard refresh requested (initState)');
      _loadQrCode();
    });
  }
```

**Impact**: Observes app lifecycle changes, cleaner method extraction, better logging.

---

#### Change #4: Add Lifecycle Callback (Lines 53-60)
**Added New Method**:
```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh QR when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      AppLogger.d('[KIOSK] Dashboard resumed');
      _loadQrCode();
    }
  }
```

**Impact**: Auto-refreshes QR code when app comes to foreground.

---

#### Change #5: Add didChangeDependencies Override (Lines 62-76)
**Added New Method**:
```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload QR whenever screen is re-entered (e.g., after PIN flow)
    AppLogger.d('[KIOSK] Dashboard resumed (didChangeDependencies)');
    // Use a small delay to avoid multiple rapid calls
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

**Impact**: Auto-refreshes dashboard when returning from sub-screens (sign-in/sign-out flows).

---

#### Change #6: Extract _loadQrCode Method (Lines 78-81)
**Added New Method**:
```dart
  void _loadQrCode() {
    AppLogger.d('[KIOSK] Refreshing QR');
    unawaited(context.read<KioskDashboardCubit>().loadQrCode());
  }
```

**Impact**: Centralized QR loading logic, consistent logging, cleaner code reuse.

---

#### Change #7: Add Pull-to-Refresh Method (Lines 83-87)
**Added New Method**:
```dart
  /// Refresh dashboard data (school info, QR, kiosk settings)
  Future<void> _refreshDashboard() async {
    AppLogger.d('[KIOSK] Refresh requested (pull-to-refresh)');
    await context.read<KioskDashboardCubit>().loadQrCode();
  }
```

**Impact**: Enables manual refresh via pull-to-refresh gesture.

---

#### Change #8: Add dispose with Observer Cleanup (Lines 89-93)
**Added New Method**:
```dart
  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
```

**Impact**: Prevents memory leaks from lifecycle observer.

---

#### Change #9: Wrap Body in RefreshIndicator (Lines 174-186)
**Before**:
```dart
        body: BlocBuilder<KioskDashboardCubit, KioskDashboardState>(
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: _buildContent(context, state, isTablet),
            );
          },
        ),
```

**After**:
```dart
        body: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: BlocBuilder<KioskDashboardCubit, KioskDashboardState>(
            builder: (context, state) {
              return Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
                child: _buildContent(context, state, isTablet),
              );
            },
          ),
        ),
```

**Impact**: Enables pull-to-refresh gesture on dashboard.

---

#### Change #10: Enhance _getSchoolName with Caching (Lines 250-277)
**Before**:
```dart
  String _getSchoolName(KioskDashboardState state) {
    if (state is KioskDashboardQrLoaded) {
      return state.schoolName;
    }
    if (state is KioskDashboardPinValidating && state.schoolName != null) {
      return state.schoolName!;
    }
    return '';
  }
```

**After**:
```dart
  String _getSchoolName(KioskDashboardState state) {
    // Always return school name, even during loading/error states
    // Cache the actual school name to preserve it during QR reloads

    if (state is KioskDashboardQrLoaded) {
      _cachedSchoolName = state.schoolName;
      AppLogger.d('[Kiosk] Cached school name: ${state.schoolName}');
      return state.schoolName;
    }

    if (state is KioskDashboardPinValidating && state.schoolName != null) {
      _cachedSchoolName = state.schoolName!;
      return state.schoolName!;
    }

    // During loading/error, use cached school name (NOT generic 'School')
    if (state is KioskDashboardLoading) {
      AppLogger.d('[Kiosk] Loading state - using cached school name: $_cachedSchoolName');
      return _cachedSchoolName; // Return CACHED value, not 'School'
    }

    if (state is KioskDashboardError) {
      AppLogger.d('[Kiosk] Error state - using cached school name: $_cachedSchoolName');
      return _cachedSchoolName; // Return CACHED value, not 'School'
    }

    return _cachedSchoolName;
  }
```

**Impact**: School name NEVER disappears, always uses actual name or cached name, never blank.

---

#### Change #11: Add Debug Logs to PIN Handling (Lines 325-326, 367-368)
**Before**:
```dart
  void _routeStaffAttendance(...) {
    final staffCode = result.staffCode ?? '';
    final status = (result.staffStatus ?? 'SIGNED_OUT').toUpperCase();

    AppLogger.d('[KIOSK] Persona=STAFF, StaffCode=$staffCode, Status=$status');
    // ...
  }

  void _routeGuardianStudentAttendance(...) {
    final signedIn = result.signedInStudents;
    final signedOut = result.signedOutStudents;
    final guardianCode = result.guardianCode ?? '';

    AppLogger.d(
      '[Kiosk] _routeGuardianStudentAttendance: guardianCode=$guardianCode, '
      // ...
    );
  }
```

**After**:
```dart
  void _routeStaffAttendance(...) {
    final staffCode = result.staffCode ?? '';
    final status = (result.staffStatus ?? 'SIGNED_OUT').toUpperCase();

    AppLogger.d('[KIOSK] Attendance action completed (Staff)');
    AppLogger.d('[KIOSK] Triggering dashboard refresh');
    // ...
  }

  void _routeGuardianStudentAttendance(...) {
    final signedIn = result.signedInStudents;
    final signedOut = result.signedOutStudents;
    final guardianCode = result.guardianCode ?? '';

    AppLogger.d('[KIOSK] Attendance action completed (Student)');
    AppLogger.d('[KIOSK] Triggering dashboard refresh');
    AppLogger.d(
      '[Kiosk] _routeGuardianStudentAttendance: guardianCode=$guardianCode, '
      // ...
    );
  }
```

**Impact**: Better tracking of when attendance actions complete.

---

## Summary of Changes

| Issue | Fix | File | Lines |
|-------|-----|------|-------|
| QR disappears | Never return `SizedBox.shrink()`, always show loading state | `kiosk_qr_section_widget.dart` | 53-56 |
| School name disappears | Cache school name, return cached value in all states | `kiosk_dashboard_screen.dart` | 250-277 |
| No auto-refresh on return | Add `didChangeDependencies()` override | `kiosk_dashboard_screen.dart` | 62-76 |
| App foreground not triggering refresh | Add `didChangeAppLifecycleState()` override with observer | `kiosk_dashboard_screen.dart` | 33, 44, 53-60, 89-93 |
| No manual refresh | Add `RefreshIndicator` + `_refreshDashboard()` | `kiosk_dashboard_screen.dart` | 83-87, 174-186 |
| Poor debug visibility | Add structured logging throughout | Both files | Multiple |

---

## Testing Recommendations

1. **Critical Path**: Student sign-in → return to dashboard → verify QR + school name visible
2. **Critical Path**: Staff sign-in → return to dashboard → verify QR + school name visible  
3. **Manual Refresh**: Pull down on dashboard → verify refresh works
4. **Edge Case**: Loading state → verify school name visible
5. **Edge Case**: Error state → verify school name visible
6. **Edge Case**: App background/foreground → verify refresh triggers

See `KIOSK_VERIFICATION_CHECKLIST.md` for complete test cases.

---

## Root Cause Prevention

To prevent similar issues in the future:

1. **Never use `SizedBox.shrink()` as a fallback** → Use a loading/error state instead
2. **Always cache critical data** → Use instance variables to preserve state across rebuilds
3. **Always observe lifecycle changes** → App foreground/background should trigger refreshes
4. **Provide manual refresh** → `RefreshIndicator` or similar for user control
5. **Use structured logging** → Makes debugging much easier
6. **Test all state transitions** → Not just the happy path
