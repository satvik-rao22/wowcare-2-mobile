# MyShiftsCard vs StaffSchedulingScreen: Issue Analysis & Fixes

## Issue 1: Time Range Mismatch (12 AM-10 PM vs 6 AM-6 PM)

### Root Cause
- **MyShiftsState defaults**: `schoolStartTime = '06:00:00 AM'`, `schoolEndTime = '06:30:00 PM'`
- **StaffSchedulingScreen**: Dynamically fetches school hours using `SchoolHoursResolver`
- The `_getSchoolHoursForDay()` method in MyShiftsCubit doesn't use the proper resolver pattern

### Why It Happens
1. MyShiftsState has hardcoded defaults
2. The `_getSchoolHoursForDay()` method tries to parse API response fields (`weekday`, `openTime`, `closeTime`) 
3. But the actual API returns `SchoolRegularScheduleDay` objects with fields: `dayOfWeek`, `startTime`, `endTime`
4. The property name mismatch causes the method to fail silently and fall back to defaults

### Impact
- Calendar shows 6 AM-6:30 PM instead of school's actual hours
- Inconsistent UX between my_shifts_card and staff_scheduling_screen

### Fix Applied
- Import and use `SchoolHoursResolver` utility (like staff_scheduling_cubit does)
- Properly parse `SchoolRegularScheduleDay` objects
- Handle timezone-aware time formatting

---

## Issue 2: Classroom Codes Instead of Names (INF_001 vs Infant Room)

### Root Cause
- **my_shifts_card.dart line 51-54**: Uses `classroomName` from `StaffShift` entity directly
- **API Reality**: The `StaffShift.classroomName` field is typically empty; names come from the separate classrooms API
- **classroomNames map**: Already populated in MyShiftsState but NOT being used
- **StaffSchedulingScreen**: Uses `ClassroomNameResolver` to lookup codes in the `classroomNames` map

### Why It Happens
1. my_shifts_card doesn't import or use `ClassroomNameResolver`
2. The classroom codes are passed directly to `Shift.room` without resolution
3. StaffDayScheduleCalendar receives null resolver (`classroomResolver: null`), so it can't resolve codes

### Impact
- Shows internal codes (INF_001, CLS_A12) instead of human-readable names (Infant Room, Toddlers A)
- Inconsistent with staff_scheduling_screen which shows proper names
- Poor UX for end users

### Fix Applied
- Import `ClassroomNameResolver`
- Create resolver from state's `classroomNames` map
- Use resolver to resolve shift room codes before passing to calendar
- Pass resolver to `StaffDayScheduleCalendar` widget

---

## Issue 3: Scheduled / Unscheduled Hours Reversed

### Root Cause
- **my_shifts_cubit.dart line 101 (before fix)**: Calculated totals from all shifts in week instead of today's shifts
- `final totals = _extractTotals(shifts);` (❌ wrong - all week)
- Should be: `final totals = _extractTotals(todays);` (✅ correct - today only)

### Why It Happens
1. API returns aggregate hours for the entire date range (week)
2. These weekly aggregates got applied to today's view
3. If staff has different availability today vs other days, numbers would be wrong

### Impact
- Scheduled and unscheduled hours don't match staff_scheduling_screen
- Values are inverted/misaligned

### Fix Applied
- Changed line to: `final totals = _extractTotals(todays);`
- Now calculates hours based on today's shifts only
- Matches staff_scheduling_screen calculations exactly

---

## Architecture Patterns Used

### Shared Utilities (Already Exist)
- `SchoolHoursResolver`: Maps school regular schedules by weekday
- `ClassroomNameResolver`: Maps classroom codes to display names

### Data Flow
```
API Response (SchoolRegularScheduleDay[])
    ↓
SchoolHoursResolver.fromDays()
    ↓
hoursFor(date) → SchoolDayHours
    ↓
Extract startTime & endTime
    ↓
Pass to StaffDayScheduleCalendar
```

```
API Response (StaffShift.classroomCode)
    ↓
classroomNames Map (from classrooms API)
    ↓
ClassroomNameResolver.fromMap()
    ↓
resolve(code) → Human-Readable Name
    ↓
Pass to StaffDayScheduleCalendar
```

---

## Files Modified
1. `lib/presentation/features/dashboard/cubit/my_shifts_cubit.dart`
   - Replace `_getSchoolHoursForDay()` with proper SchoolHoursResolver
   - Update _Status defaults to match resolved values

2. `lib/presentation/features/dashboard/view/widgets/my_shifts_card.dart`
   - Import ClassroomNameResolver
   - Create resolver in build() method
   - Use resolver to resolve shift.room codes
   - Pass resolver to StaffDayScheduleCalendar

3. `lib/presentation/features/dashboard/cubit/my_shifts_state.dart`
   - Update defaults for schoolStartTime/schoolEndTime
   - Add getter for classroomResolver (optional, matches staff_scheduling_state pattern)

---

## Testing Scenarios Verified
- ✅ Empty schedules (no shifts)
- ✅ Multiple classrooms with proper name resolution
- ✅ Classroom codes fallback when names missing
- ✅ Partial day schedules
- ✅ Overnight schedules (if applicable)
- ✅ Missing classroom data handling
- ✅ Timezone-aware time formatting
