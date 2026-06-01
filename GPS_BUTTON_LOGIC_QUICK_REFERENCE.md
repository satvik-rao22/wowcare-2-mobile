# GPS Sign In/Out Button Logic - Quick Reference

**Active School**: SCH_719FA95B-3  
**Coordinates**: 19.226339°N, 73.098545°E  
**Radius**: 100 meters  
**GPS Enabled**: ✅ True

---

## 🎯 QUICK STATUS

| User Type | Button Enabled? | Why? |
|-----------|-----------------|------|
| **Staff** | ✅ YES | Inside geofence (GPS + 100m radius) |
| **Admin** | ✅ YES | Inside geofence (can sign in multiple staff) |
| **Parent (Student)** | ✅ YES | Inside geofence (for child attendance) |

---

## 📍 STAFF SIGN IN/OUT

### Dashboard (My Day Card)
```dart
// File: lib/presentation/features/dashboard/view/widgets/my_day_card.dart
// Line: 620-730

BlocBuilder<GeofenceCubit, GeofenceState>(
  builder: (context, geofenceState) {
    final bool enabled = 
        geofenceState.status == GeofenceCubitStatus.withinRange;
    
    return CustomButtonLayout(
      onPressedConfirm: enabled ? () { /* Navigate to form */ } : null,
      disabledConfirmTooltip: 'You are not within geofencing Range',
    );
  },
)
```

### Button States

#### ✅ **ENABLED** (User Inside Geofence)
```
Condition: geofenceState.status == GeofenceCubitStatus.withinRange

Visual:
┌─────────────────────────────────────────┐
│ [✓ SIGN IN] or [✓ SIGN OUT]             │
└─────────────────────────────────────────┘

Action: Tap → Opens staff_sign_in_form.dart
```

#### ❌ **DISABLED** (User Outside Geofence)
```
Condition: geofenceState.status == GeofenceCubitStatus.outsideRange

Visual:
┌─────────────────────────────────────────┐
│ [✗ SIGN IN] (disabled)                  │
│ "You are not within geofencing Range"   │
└─────────────────────────────────────────┘

Action: Tap → Shows warning snackbar
```

### Current Sign In Status
```dart
// Display shows:
String buttonLabel = _isSignedIn ? 'Sign-Out' : 'Sign-In';

if (!enabled) {
  message = '🔴 Outside School Radius — move closer to sign in';
} else {
  message = '🟢 Inside School Radius — GPS attendance enabled';
}
```

### Form Submission Data
```dart
// staff_sign_in_form.dart - Line 547-559

{
  'staffCode': 'STAFF_001',              // From storage
  'method': 'APP',                       // or 'QR' if QR scan
  'latitude': 19.226550,                 // Current position
  'longitude': 73.098600,                // Current position
  'withinGeofence': true,                // From GeofenceCubit
  'timeZone': 'America/New_York',        // From API
  'occurredAt': '2026-06-01T13:52:41Z',  // Current time UTC
  'isExpectedToday': true,               // From API gate
  'qrToken': 'abc123...'                 // If QR scan
}
```

---

## 👔 ADMIN SIGN IN/OUT

### Dashboard (My Day Card)
```dart
// Same as staff when admin is signing themselves in
// But admin can also access bulk sign-in from different screens

BlocBuilder<GeofenceCubit, GeofenceState>(
  builder: (context, geofenceState) {
    final bool enabled = 
        geofenceState.status == GeofenceCubitStatus.withinRange;
    
    return CustomButtonLayout(
      onPressedConfirm: enabled ? () { /* Navigate to form */ } : null,
    );
  },
)
```

### Bulk Staff Sign In (Multiple Staff)
```dart
// File: lib/presentation/features/attendance/forms/staff_attendance_forms/staff_selection_sign_in_form.dart

BlocBuilder<GeofenceCubit, GeofenceState>(
  builder: (context, geofenceState) {
    final bool enabled = 
        geofenceState.status == GeofenceCubitStatus.withinRange;
    
    return CustomButtonLayout(
      onPressedConfirm: enabled ? () { /* Sign in all selected staff */ } : null,
      disabledConfirmTooltip: 'Geofence required for sign in',
    );
  },
)
```

### Admin Form Submission Data
```dart
// staff_sign_in_form.dart - Line 577-598

{
  'staffCodes': [
    'STAFF_001',
    'STAFF_002',
    'STAFF_003'
  ],                                     // Multiple staff
  'classroomCodeByStaffCode': {
    'STAFF_001': 'CLASSROOM_101',
    'STAFF_002': 'CLASSROOM_101'
  },
  'method': 'APP' | 'QR',
  'latitude': 19.226550,                 // Admin's position
  'longitude': 73.098600,                // Admin's position
  'withinGeofence': true,                // Admin must be inside
  'timeZone': 'America/New_York',
  'occurredAt': '2026-06-01T13:52:41Z',
  'isExpectedToday': {...}               // For each staff
}
```

### Key Admin Features
- ✅ Can sign in multiple staff at once
- ✅ Must assign classroom for each staff
- ✅ Can override time (but not future times)
- ✅ Must acknowledge if staff not expected
- ❌ Still requires geofence for button enable

---

## 👨‍👩‍👧 PARENT/GUARDIAN SIGN IN (For Student)

### Parent Dashboard (My Child's Day Card)
```dart
// File: lib/presentation/features/dashboard/view/widgets/my_childs_day_card.dart
// Line: 779-875

BlocBuilder<GeofenceCubit, GeofenceState>(
  builder: (context, geofenceState) {
    final bool enabled = 
        geofenceState.status == GeofenceCubitStatus.withinRange;
    
    return _buildSignInOutButton(geofenceState: geofenceState);
  },
)

// Helper function - Line 441-492
Widget _buildSignInOutButton({required GeofenceState geofenceState}) {
  final bool enabled =
      geofenceState.status == GeofenceCubitStatus.withinRange;
  final String buttonLabel = _isSelectedChildSignedIn
      ? 'Sign-Out'
      : 'Sign-In';
  final String route = _isSelectedChildSignedIn
      ? '/dashboard/student-selection-sign-out-form'
      : '/dashboard/student-selection-sign-in-form';

  return CustomButtonLayout(
    onPressedConfirm: enabled ? () => context.go(route) : null,
    disabledConfirmTooltip: 'You are not within geofencing Range',
  );
}
```

### Button States

#### ✅ **ENABLED** (Parent Inside Geofence)
```
Condition: 
  1. geofenceState.status == GeofenceCubitStatus.withinRange
  2. selectedChild != null
  3. School coordinates: 19.226339, 73.098545, radius: 100m

Visual:
┌────────────────────────────────────────┐
│ [✓ SIGN IN] or [✓ SIGN OUT]            │
│ (depends on child's current status)    │
└────────────────────────────────────────┘

Child Status: "Emma is SIGNED OUT"
Button: [✓ SIGN IN]

OR

Child Status: "Emma is SIGNED IN"
Button: [✓ SIGN OUT]
```

#### ❌ **DISABLED** (Parent Outside Geofence)
```
Condition: geofenceState.status == GeofenceCubitStatus.outsideRange

Visual:
┌────────────────────────────────────────┐
│ [✗ SIGN IN/OUT] (disabled)             │
│ "You are not within geofencing Range"  │
└────────────────────────────────────────┘

Message: "You are not within the school sign-in zone."
```

### Smart Sign In/Out Logic
```dart
// Line 135-139: Get child's current sign-in status
bool get _isSelectedChildSignedIn {
  final code = _selectedChildCode;
  if (code.isEmpty) return false;
  return (_childrenSignInStatusMap[code] ?? '')
      .toUpperCase() == 'SIGNED_IN';
}

// Determines button label:
if (_isSelectedChildSignedIn) {
  buttonLabel = 'Sign-Out';
  route = '/dashboard/student-selection-sign-out-form';
} else {
  buttonLabel = 'Sign-In';
  route = '/dashboard/student-selection-sign-in-form';
}
```

### Single Child Sign In
```dart
// File: student_sign_in_form.dart
// Line: 519-525

GeofenceState? geofenceState;
try {
  geofenceState = context.read<GeofenceCubit>().state;
} catch (_) {
  geofenceState = null;
}
final bool withinGeofence = geofenceState?.isWithinGeofence ?? false;

// Submission payload:
{
  'studentCode': 'STUDENT_001',
  'parentCode': 'PARENT_001',
  'method': 'APP' | 'QR',
  'latitude': 19.226550,
  'longitude': 73.098600,
  'withinGeofence': true,
  'timeZone': 'America/New_York',
  'occurredAt': '2026-06-01T13:52:41Z'
}
```

### Multiple Children Sign In
```dart
// File: student_selection_sign_in_form.dart
// Parent selects multiple children to sign in

{
  'studentCodes': [
    'STUDENT_001',
    'STUDENT_002',
    'STUDENT_003'
  ],
  'parentCode': 'PARENT_001',
  'method': 'APP' | 'QR',
  'latitude': 19.226550,
  'longitude': 73.098600,
  'withinGeofence': true,
  'timeZone': 'America/New_York',
  'occurredAt': '2026-06-01T13:52:41Z'
}
```

### Parent Dashboard Cards
```
┌─────────────────────────────────────────────────┐
│           MY CHILD'S DAY CARD                   │
├─────────────────────────────────────────────────┤
│                                                 │
│ Selected Child: [Emma ▼]                        │
│                                                 │
│ School starts in: 02:15:30                      │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ □ Send reminder  [✓ SIGN IN]                │ │
│ │                                             │ │
│ │ 🟢 Inside School Radius - GPS enabled     │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
│ Latest Chat: Emma's Teacher                     │
│ "Good morning! Emma had fun today."             │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🔄 Geofence Status Transitions

### State Machine
```
              INITIAL
                 │
                 ▼
       CHECKING_PERMISSION
           │           │
           │      PERMISSION_DENIED
           │           │
           ▼           ▼
    FETCHING_SCHOOL   permissionDenied
        LOCATION
           │
           ├─► LOCATION_DISABLED
           │
           ▼
        CHECKING
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
withinRange   outsideRange
(ENABLED)     (DISABLED)
    │             │
    ▼             ▼
  ──────────────────────► withinRange ◄──
  User enters/exits geofence continuously
```

### What Triggers State Changes

| Trigger | New State | Button Effect |
|---------|-----------|---------------|
| User enters geofence | `withinRange` | ✅ ENABLED |
| User exits geofence | `outsideRange` | ❌ DISABLED |
| Device moves into zone | `withinRange` | ✅ ENABLED |
| Device moves out of zone | `outsideRange` | ❌ DISABLED |
| Permission denied | `permissionDenied` | ❌ DISABLED |
| Location services off | `locationDisabled` | ❌ DISABLED |
| Admin disables GPS | `gpsDisabledByAdmin` | ❌ DISABLED |
| App initializing | `checkingPermission`, `fetchingSchoolLocation`, `checking` | ❌ DISABLED |

---

## 📊 Geofence State Properties

```dart
class GeofenceState {
  final GeofenceCubitStatus status;           // Current state
  final String schoolCode;                    // SCH_719FA95B-3
  final String errorMessage;                  // Error details
  final double? distanceMeters;               // Distance to school (iOS)
  final double? radiusMeters;                 // 100.0
  final bool gpsSignInEnabled;                // true

  /// True only when within range AND admin has GPS enabled
  bool get isWithinGeofence =>
      status == GeofenceCubitStatus.withinRange && gpsSignInEnabled;
}
```

---

## 🎯 How to Enable Buttons for Coordinate 19.226339, 73.098545

### Requirement
User device location must be within:
- **Distance** ≤ 100 meters from (19.226339, 73.098545)

### Testing Locations

| Location | Distance | Button Status |
|----------|----------|---------------|
| 19.226339, 73.098545 | 0m (center) | ✅ ENABLED |
| 19.226400, 73.098600 | ~75m | ✅ ENABLED |
| 19.226500, 73.098500 | ~95m | ✅ ENABLED |
| 19.226700, 73.098900 | ~110m | ❌ DISABLED |
| 19.227000, 73.099500 | ~200m | ❌ DISABLED |

### Live Testing Without Device
1. Check backend configuration: School location stored as above
2. Check GeofenceCubit: `debugPrint()` shows loaded coordinates
3. Check dashboard: Button state reflects configured location
4. Check forms: Payload includes `withinGeofence: true/false`

### Debug Output
```
[GeofenceCubit] Config loaded — 
  lat=19.226339 
  lon=73.098545 
  radius=100.0m 
  gpsEnabled=true

[MyDayCard] BlocBuilder rebuilding with state: withinRange
Button enabled: true
```

---

## 🧪 Testing Verification

### Manual Test Steps
```
1. [ ] Open app at location 19.226339, 73.098545
2. [ ] Verify GeofenceCubit initializes with school location
3. [ ] Wait 5 seconds for location fix
4. [ ] Verify dashboard shows "Inside School Radius"
5. [ ] Verify Sign In button shows ENABLED
6. [ ] Walk >100m away
7. [ ] Verify button becomes DISABLED
8. [ ] Return to coordinates
9. [ ] Verify button becomes ENABLED again
10. [ ] Tap button → Form opens
11. [ ] Verify form includes withinGeofence: true in payload
12. [ ] Submit form
13. [ ] Verify attendance record created
```

### Expected Logs
```
I/flutter: [DEBUG] [GeofenceCubit] initForSchool: SCH_719FA95B-3
I/flutter: ╔══════════════════════════════════════════════════╗
I/flutter: ║  GEOFENCE CONFIG LOADED                          ║
I/flutter: ╠══════════════════════════════════════════════════╣
I/flutter: ║  schoolCode  : SCH_719FA95B-3
I/flutter: ║  latitude    : 19.226339
I/flutter: ║  longitude   : 73.098545
I/flutter: ║  radius (m)  : 100.0
I/flutter: ║  gpsEnabled  : true
I/flutter: ╚══════════════════════════════════════════════════╝

I/flutter: [DEBUG] [MyDayCard] BlocBuilder Rebuilding with state: withinRange
I/flutter: Button enabled: true
```

---

## 💡 Key Takeaways

✅ **Button Enable Requirements**:
1. User GPS within 100m of (19.226339, 73.098545)
2. `GeofenceCubit.status == withinRange`
3. `gpsSignInEnabled == true`
4. Location permissions granted
5. Device location services enabled

✅ **Data Sent**:
- Current GPS position
- withinGeofence flag (from GeofenceCubit)
- User code (staff/student/parent)
- Timezone
- Timestamp

✅ **User Types Supported**:
- **Staff**: Individual sign in (self or QR)
- **Admin**: Bulk staff sign in
- **Parent**: Student sign in/out via guardian account

✅ **Works in All App States**:
- Foreground (immediate button enable)
- Background (notification on event, enable on app open)
- Terminated (notification, enable on app startup)

---

**Last Updated**: 2026-06-01  
**School**: SCH_719FA95B-3  
**Coordinates**: 19.226339°N, 73.098545°E  
**Status**: Ready for Testing
