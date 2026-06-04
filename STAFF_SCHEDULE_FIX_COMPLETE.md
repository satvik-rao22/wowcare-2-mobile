# My Day Card - Staff Schedule Only Fix (Complete)

## Problem Statement

The My Day Card countdown was using:
- ❌ School timezone logic (America/New_York)
- ❌ School regular schedule as fallback
- ❌ Random/arbitrary school timings
- ❌ Timezone conversion that shifted dates

Instead of using:
- ✅ ONLY staff work schedules API
- ✅ Device local time
- ✅ No timezone conversion

---

## Root Cause Analysis

### Original Broken Logic

```dart
// OLD CODE - WRONG
final now = schoolTimeZone.isNotEmpty
    ? SchoolZoneDateTime.dateTimeFromInstantInSchool(DateTime.now().toUtc(), schoolTimeZone)
    : DateTime.now();

// This timezone conversion could shift the date/time, causing:
// - Day matching failures (THURSDAY becomes FRIDAY after conversion)
// - staffWs=null when it shouldn't be null
// - Fallback to school schedule used incorrectly
```

### Why This Caused Issues

1. **Timezone Shifting Date**: Converting to "America/New_York" timezone could shift the current day
   - If local time was Thursday 23:00, it might become Friday 04:00 after conversion
   - Staff schedule for Thursday wouldn't match Friday

2. **School Schedule Fallback**: When staff schedule became null due to date mismatch, code fell back to school schedule
   - This was incorrect - should ONLY use staff schedules

3. **Random Timings**: When school schedule parsing failed, it used arbitrary defaults (00:00 = midnight)

4. **No API Correlation**: The countdown had no direct correlation to the actual staff schedule API response

---

## The Fix: Complete Rewrite

### Changes Made

**File: `lib/presentation/features/dashboard/view/widgets/my_day_card.dart`**

#### 1. ❌ REMOVED

- `SchoolZoneDateTime` import (timezone conversion)
- School timezone logic entirely
- School regular schedule countdown logic
- Fallback to school schedule
- `_normalize24h()` method (was parsing school schedule times)
- `_fmtHM()` method (was for school schedule)
- `_applyNextShift()` method (had school timezone logic)

#### 2. ✅ REPLACED WITH NEW IMPLEMENTATION

```dart
void _computeCountdownFromSchedule(
  SchoolRegularScheduleDay? schedule, {  // ignored - only for API compatibility
  StaffProfileWorkSchedule? staffSchedule,
  StaffProfileBreakSchedule? breakSchedule,
  String schoolTimeZone = '',  // ignored - no longer used
  List<StaffProfileWorkSchedule> allWorkSchedules = const [],  // ONLY THIS IS USED
  List<StaffProfileBreakSchedule> allBreakSchedules = const [],
})
```

**Key Changes:**
```dart
// Use DEVICE LOCAL TIME only (NO timezone conversion)
final now = DateTime.now();
final todayWeekday = now.weekday; // 1=Monday, 7=Sunday

// Find today's staff schedule from allWorkSchedules
final todaySchedule = _resolveWorkScheduleForDay(todayWeekday, allWorkSchedules);

// If today has schedule and it hasn't passed, show countdown
if (todaySchedule != null) {
  // ... countdown logic using ONLY staff schedule times
}

// If today's schedule passed, find next upcoming schedule
_applyNextStaffShift(now, todayWeekday, allWorkSchedules, allBreakSchedules);
```

### New Method: `_applyNextStaffShift()`

Completely rewritten to use device local time:

```dart
void _applyNextStaffShift(
  DateTime now,  // device local time
  int todayWeekday,
  List<StaffProfileWorkSchedule> allWork,
  List<StaffProfileBreakSchedule> allBreak,
) {
  // Build maps from staff schedules (NOT school schedule)
  final schedulesByWeekday = <int, StaffProfileWorkSchedule>{};
  
  for (final ws in allWork) {
    final wd = _kDayToWeekday[ws.dayOfWeek.trim().toUpperCase()];
    if (wd != null) {
      schedulesByWeekday[wd] = ws;  // ONLY staff schedules
    }
  }
  
  // Search next 7 days for upcoming staff schedule
  for (int daysAhead = 1; daysAhead <= 7; daysAhead++) {
    final futureDate = now.add(Duration(days: daysAhead));
    final schedule = schedulesByWeekday[futureDate.weekday];
    
    if (schedule != null) {
      // Found next staff schedule - show countdown
      final startDt = DateTime(futureDate.year, futureDate.month, futureDate.day,
          schedule.workStartTime.hour, schedule.workStartTime.minute, 0);
      
      _setCountdownState(
        isTodayShift: false,
        hasShifts: true,
        duration: startDt.difference(now),  // exact countdown
        workStart: _formatStaffTime(schedule.workStartTime),
        workEnd: _formatStaffTime(schedule.workEndTime),
        dayAbbr: _dayAbbr(schedule.dayOfWeek),
        breakTime: _formatBreakDisplay(breaksByWeekday[futureDate.weekday]),
        statusText: 'Your next shift starts in',
        nextDayName: _getDayName(futureDate.weekday),
      );
      return;
    }
  }
}
```

### New Helper Method: `_setCountdownState()`

Consolidates state setting logic:

```dart
void _setCountdownState({
  required bool isTodayShift,
  required bool hasShifts,
  required Duration duration,
  required String workStart,
  required String workEnd,
  required String dayAbbr,
  required String breakTime,
  required String statusText,
  String nextDayName = '',
}) {
  setState(() {
    _isTodayShift = isTodayShift;
    _nextDayName = nextDayName;
    _hasShifts = hasShifts;
    _duration = duration;
    _workTime = '$workStart - $workEnd ($dayAbbr)';
    _breakTime = breakTime;
    _statusText = statusText;
  });
}
```

---

## How It Works Now

### Flow Diagram

```
1. Widget loads
   ↓
2. Get current device local time (DateTime.now())
   ↓
3. Determine today's weekday (1=Mon, 7=Sun)
   ↓
4. Look for today's schedule in allWorkSchedules
   ├─ IF TODAY HAS SCHEDULE
   │  ├─ AND shift hasn't started → countdown to start time
   │  ├─ AND shift is active → countdown to end time
   │  └─ AND shift already ended → go to step 5
   │
   └─ IF NO TODAY SCHEDULE OR PASSED
      ↓
5. Search next 7 days for upcoming staff schedule
   ├─ Found → show countdown to that date's start time
   └─ Not found → show "No upcoming shifts"
```

### Example Scenarios

**Scenario 1: Today is Thursday, staff has Thursday schedule**
```
now = 2026-06-04 08:00 (Thursday 8:00 AM, device local time)
todayWeekday = 4 (Thursday)
allWorkSchedules = [
  { dayOfWeek: "THURSDAY", start: 09:00, end: 17:00 },
  { dayOfWeek: "FRIDAY", start: 08:00, end: 20:00 }
]

Result:
- Today's schedule found (THURSDAY 09:00 - 17:00)
- Shift hasn't started yet (now 08:00 < start 09:00)
- Shows countdown to 09:00 (1 hour)
```

**Scenario 2: Today is Thursday, today's shift already passed**
```
now = 2026-06-04 18:00 (Thursday 6:00 PM, device local time)
todayWeekday = 4 (Thursday)
allWorkSchedules = [
  { dayOfWeek: "THURSDAY", start: 09:00, end: 17:00 },
  { dayOfWeek: "FRIDAY", start: 08:00, end: 20:00 }
]

Result:
- Today's schedule found (THURSDAY 09:00 - 17:00)
- Shift already passed (now 18:00 > end 17:00)
- Search next 7 days
- Found FRIDAY 08:00 - 20:00
- Shows countdown to Friday 08:00
```

**Scenario 3: Today is Thursday, no Thursday schedule**
```
now = 2026-06-04 12:00 (Thursday 12:00 PM, device local time)
todayWeekday = 4 (Thursday)
allWorkSchedules = [
  { dayOfWeek: "FRIDAY", start: 08:00, end: 20:00 }
]

Result:
- Today's schedule NOT found
- Search next 7 days
- Found FRIDAY 08:00 - 20:00 (1 day away)
- Shows countdown to Friday 08:00
```

---

## Debug Output

### Console Logs Now Show

```
[MyDayCard] Computing countdown: 
  today=weekday4 (Thursday), 
  now=08:00:30, 
  allScheduleCount=5

[MyDayCard] Today has schedule: 09:00 - 17:00

[MyDayCard] Next schedule found: Friday 08:00
```

### Old Broken Logs (No Longer Seen)

```
[MyDayCard] Computing countdown for 4 (Thursday):
tz=America/New_York,
staffWs=null@null:null,
allCount=3
```

---

## API Data Flow

### What Gets Used

```
API Response: /api/v1/staff/staff-schedules/{staffId}
{
  "workSchedules": [
    {
      "dayOfWeek": "MONDAY",
      "workStartTime": "11:00:00",
      "workEndTime": "19:00:00"
    },
    {
      "dayOfWeek": "THURSDAY",
      "workStartTime": "09:00:00",
      "workEndTime": "17:00:00"
    },
    {
      "dayOfWeek": "FRIDAY",
      "workStartTime": "08:00:00",
      "workEndTime": "20:00:00"
    }
  ]
}
     ↓
   (No transformation, used as-is)
     ↓
allWorkSchedules = [MONDAY, THURSDAY, FRIDAY schedules]
     ↓
   (Match against device local time)
     ↓
Countdown displayed
```

---

## Removed Code

These are completely removed (no longer needed):

1. **SchoolZoneDateTime import** - No timezone conversion
2. **schoolTimeZone parameter usage** - Not used in countdown logic
3. **School regular schedule logic** - Only staff schedules matter
4. **_normalize24h()** - Was parsing school times
5. **_fmtHM()** - Was for school schedule formatting
6. **_applyNextShift()** - Had timezone logic
7. **All DateTime conversion logic** - Uses device local time now

---

## Testing Checklist

- [ ] Run app and open Dashboard
- [ ] Check console logs:
  - Should see `[MyDayCard] Computing countdown:` logs
  - Should NOT see timezone information
  - Should NOT see school schedule references
  - Should show actual staff schedule times
- [ ] Verify countdown matches staff schedule API response
- [ ] Test different scenarios:
  - [ ] Today has schedule, hasn't started
  - [ ] Today has schedule, currently active
  - [ ] Today has schedule, already passed
  - [ ] Today has no schedule
  - [ ] No schedules at all
- [ ] Verify countdown updates every second
- [ ] Verify next shift found correctly when today's passed
- [ ] Verify empty state shows when no schedules

---

## What Changed

| Aspect | Before | After |
|--------|--------|-------|
| Time source | School timezone (America/New_York) | Device local time |
| Fallback logic | School regular schedule | None - only staff schedules |
| Schedule source | School + staff (fallback) | Staff ONLY |
| Date shifting | Could shift due to timezone | No - local time only |
| Timezone conversion | Yes (SchoolZoneDateTime) | No |
| Imports | SchoolZoneDateTime | Removed |
| Key method | `_applyNextShift(schoolNow, ...)` | `_applyNextStaffShift(now, ...)` |

---

## Production Deployment

### Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Console logs show staff schedule matching (not school schedule)
- [ ] Countdown values match staff API response exactly
- [ ] No timezone conversion happening
- [ ] Memory usage normal (no leaks)
- [ ] Timer properly disposed on widget disposal
- [ ] All edge cases tested

### Post-Deployment Monitoring

- [ ] Check for "No upcoming shifts" false positives
- [ ] Verify countdown accuracy (compare to clock)
- [ ] Monitor for any null pointer exceptions
- [ ] Check device logs for schedule matching issues
- [ ] Verify timer updates are smooth (1-second intervals)

---

## Summary

The My Day Card countdown is now:

✅ **Simple** - No complex timezone logic  
✅ **Direct** - Uses staff API data exactly as-is  
✅ **Accurate** - Uses device local time only  
✅ **Reliable** - No falling back to arbitrary school schedules  
✅ **Traceable** - Debug logs show exact schedule matching  
✅ **Portable** - Works regardless of device timezone  

The countdown will always show the next upcoming staff work schedule from the API, calculated using device local time, with no arbitrary defaults or timezone conversions.
