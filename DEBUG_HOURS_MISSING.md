# Debugging: Missing Hours Display in MyShiftsCard

## Issue Summary
Hours values (availableHours, scheduledHours, unscheduledHours) are not visible in my_shifts_card.dart UI, even though the API returns correct values (12.0, 12.0, 0.0).

## API Response Confirmed
```json
{
  "availableHours": 12.0,
  "scheduledHours": 12.0,
  "unscheduledHours": 0.0
}
```

---

## Debug Logs Added

### 1. In MyShiftsCubit.load() - Lines 103-110
Logs the individual shift values and extracted totals:

```dart
// DEBUG: Log the extracted totals
AppLogger.d('[MyShiftsCubit] Today has ${todays.length} shifts');
for (var (i, shift) in todays.indexed) {
  AppLogger.d('[MyShiftsCubit] Shift $i: avail=${shift.availableHours}, sched=${shift.scheduledHours}, unsched=${shift.unscheduledHours}');
}
AppLogger.d('[MyShiftsCubit] Extracted Totals: avail=${totals.availableHours}, sched=${totals.scheduledHours}, unsched=${totals.unscheduledHours}');
```

**What to look for in logs:**
- Check if shifts are being found for today
- Verify extracted totals match API response
- If values are 0, the issue is in data fetching/parsing

### 2. In MyShiftsCubit.load() - Before emit - Lines 160-161
Logs the state object before it's emitted to the UI:

```dart
// DEBUG: Log the state before emitting
AppLogger.d('[MyShiftsCubit] State to emit: avail=${newState.availableHours}, sched=${newState.scheduledHours}, unsched=${newState.unscheduledHours}');
```

**What to look for in logs:**
- Verify state has correct values before reaching UI
- If values are 0 here, problem is in copyWith()

### 3. In MyShiftsCard.build() - Line 153
Logs the state received in the UI build function:

```dart
// DEBUG: Log the state received from cubit
AppLogger.d('[MyShiftsCard.build] State avail=${state.availableHours}, sched=${state.scheduledHours}, unsched=${state.unscheduledHours}');
```

**What to look for in logs:**
- Verify state in UI matches state emitted from cubit
- If values are 0 here but non-zero in cubit, issue is in BlocBuilder/state management

---

## Expected Log Output (Healthy Flow)
```
[MyShiftsCubit] Today has 1 shifts
[MyShiftsCubit] Shift 0: avail=12, sched=12, unsched=0
[MyShiftsCubit] Extracted Totals: avail=12, sched=12, unsched=0
[MyShiftsCubit] State to emit: avail=12, sched=12, unsched=0
[MyShiftsCard.build] State avail=12, sched=12, unsched=0
```

---

## Potential Issues to Investigate

### Issue 1: Data Type Mismatch
**Location:** `lib/domain/features/scheduling/entities/staff_shift.dart` (lines 49-51)

**Problem:** Hours defined as `int` but API returns `double`
```dart
final int availableHours;  // ❌ API sends 12.0 (double)
final int scheduledHours;
final int unscheduledHours;
```

**Fix if needed:** Convert model fields from `int` to `double`
```dart
final double availableHours;  // ✅ Matches API
final double scheduledHours;
final double unscheduledHours;
```

**Also update MyShiftsState:**
```dart
final int availableHours;  // Change to double if entity changed
final int scheduledHours;
final int unscheduledHours;
```

### Issue 2: State Not Being Updated
**Check:** Is `copyWith()` properly passing the values?
- Line 159 in my_shifts_cubit.dart shows:
  ```dart
  availableHours: totals.availableHours,
  scheduledHours: totals.scheduledHours,
  unscheduledHours: totals.unscheduledHours,
  ```
- This looks correct

### Issue 3: BlocBuilder Not Rebuilding
**Check:** buildWhen condition (lines 138-150 in my_shifts_card.dart)
- Lines 144-146 check these fields:
  ```dart
  p.availableHours != c.availableHours ||
  p.scheduledHours != c.scheduledHours ||
  p.unscheduledHours != c.unscheduledHours ||
  ```
- This looks correct

### Issue 4: Empty State Initialization
**Check:** MyShiftsState defaults (my_shifts_state.dart line 15-17)
```dart
this.availableHours = 0,
this.scheduledHours = 0,
this.unscheduledHours = 0,
```
- These default to 0, which is correct (fallback behavior)

### Issue 5: UI Not Rendering Values
**Check:** my_shifts_card.dart lines 221-246
- ShiftHoursTile widgets are properly passed the values
- formatSchedulingHours() is called correctly
- Visibility conditions look correct

---

## How to Use These Debug Logs

1. **Run the app with these debug logs**
2. **Navigate to the dashboard**
3. **Open the "My Shifts" card**
4. **Check the Android Studio Logcat / Xcode console for these messages**
5. **Compare the three log outputs:**
   - Cubit extracted totals
   - State before emit
   - State in UI

### Example Analysis

If logs show:
```
[MyShiftsCubit] Extracted Totals: avail=0, sched=0, unsched=0
[MyShiftsCubit] State to emit: avail=0, sched=0, unsched=0
[MyShiftsCard.build] State avail=0, sched=0, unsched=0
```

**Diagnosis:** Problem is in data fetching/parsing (before cubit logic)
- Check: How StaffShift models are being created from API response
- Check: If `todays` list is empty or has shifts

If logs show:
```
[MyShiftsCubit] Extracted Totals: avail=12, sched=12, unsched=0
[MyShiftsCubit] State to emit: avail=0, sched=0, unsched=0
[MyShiftsCard.build] State avail=0, sched=0, unsched=0
```

**Diagnosis:** Problem in copyWith() or state emission
- Check: If copyWith() method is overwriting the values

If logs show:
```
[MyShiftsCubit] Extracted Totals: avail=12, sched=12, unsched=0
[MyShiftsCubit] State to emit: avail=12, sched=12, unsched=0
[MyShiftsCard.build] State avail=0, sched=0, unsched=0
```

**Diagnosis:** Problem in BlocBuilder or state comparison
- Check: buildWhen condition
- Check: If state equality is broken (Equatable)

---

## Step-by-Step Debugging Procedure

### Step 1: Run App and Check Logs
```bash
flutter clean
flutter pub get
flutter run -v 2>&1 | grep -E "\[MyShifts|\[formatScheduling"
```

### Step 2: Navigate to Dashboard
- Open app
- Go to dashboard
- Expand "My Shifts" card

### Step 3: Read Log Sequence
- Look for the three debug log messages
- Trace the values through the flow

### Step 4: Identify the Break Point
- If values are 0 in Cubit logs → data fetching issue
- If values drop to 0 in emit logs → copyWith() issue
- If values drop to 0 in UI logs → BlocBuilder issue

### Step 5: Fix Based on Findings

If **data fetching issue:**
- Check StaffShift model field types
- Check JSON parsing in repository
- Verify API response is being received

If **copyWith() issue:**
- Verify copyWith() implementation
- Check if ?? operator is overwriting values

If **BlocBuilder issue:**
- Check buildWhen condition
- Verify Equatable implementation in MyShiftsState
- Check if state is being compared correctly

---

## Files Modified for Debugging

1. **lib/presentation/features/dashboard/cubit/my_shifts_cubit.dart**
   - Added 3 debug logs in load() method
   - Lines ~103-110 and ~160-161

2. **lib/presentation/features/dashboard/view/widgets/my_shifts_card.dart**
   - Added 1 debug log in build() method
   - Line ~153
   - Added import for AppLogger

---

## How to Remove Debug Logs (When Done)

When you've identified and fixed the issue, remove these lines:

**In my_shifts_cubit.dart:**
```dart
// Remove lines 103-110:
AppLogger.d('[MyShiftsCubit] Today has ${todays.length} shifts');
for (var (i, shift) in todays.indexed) { ... }
AppLogger.d('[MyShiftsCubit] Extracted Totals: ...');

// Remove lines 160-161:
AppLogger.d('[MyShiftsCubit] State to emit: ...');
```

**In my_shifts_card.dart:**
```dart
// Remove line 153:
AppLogger.d('[MyShiftsCard.build] State avail=...');

// Remove line 10 import if no longer used:
import 'package:wowcare/core/util/logger_service.dart';
```

---

## Notes

- All debug logs use `AppLogger.d()` (proper logging framework)
- Logs are non-intrusive and don't affect production behavior
- Each log is clearly labeled with source location
- Follow the three-point trace to identify exact failure point

---

## Next Steps (After Debugging)

1. Check the logs and identify where values become 0
2. Based on findings, implement the fix
3. Verify fix works with debug logs still in place
4. Remove debug logs
5. Clean up and commit

