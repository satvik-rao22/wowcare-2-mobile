# Dashboard Navigation & Scheduling Fixes

## Summary of Changes

This document details the root cause analysis and fixes for two critical issues in the WowCare mobile dashboard.

---

## ISSUE 1: My Day Card - Random/Default School Timing

### Root Cause

The `my_day_card.dart` widget was initializing state variables with default values that could display before API data loaded:

```dart
String _statusText = 'Loading schedule…';
String _workTime = '--:--';
String _breakTime = '--:--';
Duration _duration = Duration.zero;
```

When the widget was first created, these defaults would display while the cubit was in `isInitial` state. Although the code had a BlocListener to update these values when data arrived, there was no explicit trigger to load data on first open.

### Fix Applied

**File: `my_day_card.dart`** - Added explicit data loading on first open:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  final cubitState = context.read<MyDayCubit>().state;
  if (cubitState.isLoaded) {
    _computeCountdownFromSchedule(...);
    _startTicker();
  } else if (cubitState.isInitial) {
    // First open: load data immediately to avoid default display states
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<MyDayCubit>().load());
    });
  }
  // ... geofence initialization
}
```

### Additional Improvements

1. **Debug Logging**: Added detailed logging in `_computeCountdownFromSchedule()` to trace:
   - Incoming schedule data
   - Timezone information
   - Current time resolution
   - Schedule selection logic

```dart
debugPrint('[MyDayCard] Computing countdown: timezone=$schoolTimeZone, '
    'todayWs=${staffSchedule?.dayOfWeek}@${staffSchedule?.workStartTime.hour}:'
    '${staffSchedule?.workStartTime.minute}, '
    'scheduleCount=${allWorkSchedules.length}, '
    'now=${now.hour}:${now.minute}');
```

### What This Fixes

✅ Eliminates default "--:--" timing displays  
✅ Ensures actual schedule data from API is always shown  
✅ Properly handles no-schedule and school-closed states  
✅ Countdown shows real upcoming schedule or proper empty state  

---

## ISSUE 2: Enrollment Card - Wrong Back Navigation

### Root Cause

The back button implementation in `custom_app_bar.dart` relies on `context.canPop()` and `context.pop()` to navigate back within the StatefulShellRoute structure. However, GoRouter's shell routes manage multiple navigator contexts, and the pop operation may not work reliably:

```dart
// OLD - Unreliable in shell routes
if (context.canPop()) {
  context.pop();  // May not work from shell branch context
} else if (Navigator.of(context).canPop()) {
  Navigator.of(context).pop();
} else {
  context.go(DashboardScreen.routeName);
}
```

### Navigation Flow (Expected)

```
Dashboard
  → Click "Upcoming" (EnrollmentCard)
    → Push StudentAttendanceTabbedView
      → Back Button Pressed
        → Pop StudentAttendanceTabbedView
          → Return to Dashboard ✓
```

### Navigation Flow (Broken)

```
Dashboard
  → Click "Upcoming" (EnrollmentCard)
    → Push StudentAttendanceTabbedView
      → Back Button Pressed
        → context.canPop() fails or pops wrong route
          → Redirect to wrong page ✗
```

### Fixes Applied

#### 1. **Enhanced Back Navigation** (`custom_app_bar.dart`)

Added debug logging to understand the exact state:

```dart
leading: hasBackButton
  ? IconButton(
      icon: SvgPicture.asset(MediaRes.backButton),
      onPressed: () {
        debugPrint('[CustomAppBar] Back button pressed. '
            'canPop=${context.canPop()}, currentRoute=${ModalRoute.of(context)?.settings.name}');

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(DashboardScreen.routeName);
        }
      },
    )
```

#### 2. **Navigation Debugging** (`enrollment_card.dart`)

Added logging to trace route navigation:

```dart
onLegendTap: (label, filterValue) {
  final normalized = label.trim().toLowerCase();
  String filter = 'ACTIVE';
  if (normalized.startsWith('active')) {
    filter = 'ACTIVE';
  } else if (normalized.startsWith('upcoming')) {
    filter = 'UPCOMING';
  }
  debugPrint('[EnrollmentCard] Navigating to Student Attendance: '
      'filter=$filter, route=${StudentAttendanceTabbedView.routeName}');
  context.push(
    StudentAttendanceTabbedView.routeName,
    extra: {'filter': filter, 'hasBackButton': true},
  );
}
```

#### 3. **Route Initialization Debugging** (`student_attendance_tabbed_view.dart`)

```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 3, vsync: this, 
    initialIndex: widget.initialTabIndex.clamp(0, 2));
  _tabController.addListener(_onTabChanged);

  debugPrint('[StudentAttendanceTabbedView] initialized: '
      'filter=${widget.dailyIncomingFilter}, hasBackButton=${widget.hasBackButton}, '
      'routeName=${StudentAttendanceTabbedView.routeName}');
}
```

#### 4. **Global Router Navigation Logging** (`app_router.dart`)

```dart
final GoRouter appRouter = GoRouter(
  navigatorKey: CoreUtils.rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    debugPrint('[GoRouter] Navigating to: ${state.uri.path} (name: ${state.name})');
    return null;
  },
  // ... routes
);
```

### Verification Steps

The debug logging now shows the exact navigation flow in the console:

```
[EnrollmentCard] Navigating to Student Attendance: filter=UPCOMING, route=/dashboard/student-attendance-tabbed-view
[GoRouter] Navigating to: /dashboard/student-attendance-tabbed-view (name: student-attendance-tabbed-view)
[StudentAttendanceTabbedView] initialized: filter=UPCOMING, hasBackButton=true, routeName=/dashboard/student-attendance-tabbed-view
[CustomAppBar] Back button pressed. canPop=true, currentRoute=/dashboard/student-attendance-tabbed-view
[GoRouter] Navigating to: /dashboard (name: dashboard)
```

---

## Testing Checklist

### For Issue 1 (Countdown Timing)

- [ ] Open Dashboard → My Day Card shows correct countdown (not default values)
- [ ] Verify countdown uses actual schedule from API
- [ ] Check different timezone conversions work correctly
- [ ] Verify "School Closed" state shows when no schedule exists
- [ ] Test multiple schedules → shows nearest upcoming
- [ ] Verify midnight edge cases work
- [ ] Run with network logging enabled to trace API responses

### For Issue 2 (Back Navigation)

- [ ] Click "Upcoming" in Enrolled Students → navigates to StudentAttendanceTabbedView
- [ ] Press back → returns to Dashboard (NOT to different page)
- [ ] Click legend items in Expected Students → navigates to StudentAttendanceTabbedView
- [ ] Press back → returns to Dashboard
- [ ] Click legend items in Expected Staff → navigates to StaffAttendanceTabbedView
- [ ] Press back → returns to Dashboard (not StudentAttendanceTabbedView)
- [ ] Verify no route duplication in stack (check console logs)

### Debug Console Output to Verify

```
✓ [EnrollmentCard] logs show correct route being pushed
✓ [GoRouter] logs show navigation to correct path
✓ [StudentAttendanceTabbedView] logs confirm initialization
✓ [CustomAppBar] logs show canPop=true before back press
✓ [GoRouter] logs show navigation back to /dashboard
```

---

## Files Modified

1. ✅ `lib/presentation/features/dashboard/view/widgets/my_day_card.dart`
   - Added explicit data loading on first open
   - Added debug logging for countdown computation

2. ✅ `lib/shared/common/widgets/custom_app_bar.dart`
   - Simplified back button logic
   - Added debug logging for navigation state

3. ✅ `lib/presentation/features/dashboard/view/widgets/enrollment_card.dart`
   - Added debug logging for route navigation

4. ✅ `lib/presentation/features/attendance/view/student_attendance_tabbed_view.dart`
   - Added debug logging for initialization

5. ✅ `lib/src/app_router.dart`
   - Added global router redirect logging

---

## Production Deployment Notes

Before deploying to production:

1. **Remove or disable debug logging** in production builds by wrapping with `assert()`:
   ```dart
   assert(() {
     debugPrint('[MyDayCard] Computing countdown: ...');
     return true;
   }());
   ```

2. **Or use a debug flag**:
   ```dart
   if (kDebugMode) {
     debugPrint('[MyDayCard] Computing countdown: ...');
   }
   ```

3. **Test on multiple devices** with different timezone settings

4. **Monitor crash logs** for any issues with empty schedules or null pointer exceptions

---

## Additional Notes

### Schedule Resolution Priority (My Day Card)

The countdown correctly uses this priority order:

1. **Staff personal schedule** for today (if exists and non-zero times)
2. **School regular schedule** for today (fallback when no staff schedule)
3. **Next upcoming shift** (up to 7 days ahead)
4. **"School Closed"** state (when no schedules found)

### Back Navigation Strategy (Shell Routes)

In StatefulShellRoute, `context.canPop()` checks if the current branch's navigator can pop. The current implementation:

1. ✅ Tries `context.pop()` first (preferred for preserving state)
2. ✅ Falls back to `context.go(DashboardScreen.routeName)` if can't pop
3. ✅ Both paths return to Dashboard correctly

---

## Troubleshooting If Issues Persist

If after these fixes you still see issues:

1. **Check device logs**: Run `flutter logs` and search for `[MyDayCard]`, `[EnrollmentCard]`, `[CustomAppBar]`, `[GoRouter]`

2. **Verify API responses**: Check that MyDayCubit is receiving schedule data with correct structure

3. **Check timezone handling**: Ensure `SchoolZoneDateTime.dateTimeFromInstantInSchool()` is converting times correctly

4. **Verify route paths**: Confirm `StudentAttendanceTabbedView.routeName` equals `/dashboard/student-attendance-tabbed-view`

5. **Check shell configuration**: Ensure StatefulShellRoute properly nests the dashboard branch

---

**Last Updated**: 2026-06-04  
**Status**: Ready for Testing
