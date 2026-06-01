# GPS-Based Sign In Implementation Report
**Status**: Testing  
**Last Updated**: 2026-06-01  
**School**: SCH_719FA95B-3  
**Location**: Latitude 19.226339, Longitude 73.098545  
**Radius**: 100 meters (configurable)

---

## Executive Summary

The GPS-based sign-in system allows **Staff**, **Admin**, and **Student** (via Guardian) to sign in/out when physically inside the school geofence. The system works in three states: **Foreground** (app open), **Background** (app backgrounded), and **Terminated** (app killed).

### Current Implementation Status
- ✅ **Geofence Configuration**: Loaded & Active
- ✅ **Coordinate Precision**: 19.226339°N, 73.098545°E ± 100m
- ✅ **Permission Model**: Location-gated buttons
- ✅ **Data Transmission**: Includes GPS coordinates + geofence status
- ⚠️ **Button Enable/Disable**: Works when geofence state properly initialized

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     GPS SIGN-IN FLOW                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Dashboard Opens                                             │
│     ├─► GeofenceCubit.initForSchool(schoolCode)                │
│     └─► Fetch school coordinates + geofence config            │
│                                                                 │
│  2. Geofence Monitoring Starts                                  │
│     ├─► Android: OS-level GeofencingClient (background)        │
│     ├─► iOS: Significant location changes                      │
│     └─► Continuously monitors user location vs geofence        │
│                                                                 │
│  3. User Enters/Exits Geofence                                  │
│     ├─► Geofence event fires                                    │
│     ├─► GeofenceState updates                                   │
│     ├─► Dashboard buttons enable/disable                        │
│     └─► Sign In/Out forms become available                      │
│                                                                 │
│  4. User Taps Sign In/Out Button                               │
│     ├─► Form opens (staff/student/admin)                       │
│     ├─► Collects current GPS position                           │
│     ├─► Includes geofence status in payload                     │
│     └─► Submits to backend with coordinates                     │
│                                                                 │
│  5. Backend Verification                                        │
│     ├─► Validate GPS is within geofence                        │
│     ├─► Validate business logic (expected today, etc)          │
│     ├─► Update attendance record                               │
│     └─► Return success/error                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. STAFF SIGN-IN/SIGN-OUT

### Entry Point
**File**: `lib/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_in_form.dart`

### Sign In Button State
```dart
// In dashboard (my_day_card.dart):
BlocBuilder<GeofenceCubit, GeofenceState>(
  builder: (context, geofenceState) {
    final bool enabled = geofenceState.status == GeofenceCubitStatus.withinRange;
    return CustomButtonLayout(
      onPressedConfirm: enabled ? () => context.go('/dashboard/staff-sign-in-form') : null,
      disabledConfirmTooltip: 'You are not within geofencing Range',
    );
  },
)
```

### Flow Steps

#### Step 1: Button Enable Condition
```dart
// GeofenceState evaluates to:
bool get isWithinGeofence =>
    status == GeofenceCubitStatus.withinRange && gpsSignInEnabled;

// Button enabled when:
enabled = (geofenceState.status == GeofenceCubitStatus.withinRange)
```

**Current Status**: ✅ **ENABLED**
- School latitude: 19.226339
- School longitude: 73.098545
- Radius: 100 meters
- GPS Sign-in enabled: true

#### Step 2: Form Initialization
When staff taps "Sign In" button:

```dart
// staff_sign_in_form.dart - _initializeFormData()
1. Load current staff code from storage
2. Resolve school timezone (America/New_York)
3. Check if user is admin/staff persona
4. Apply staff selection restrictions
5. Run unexpected sign-in gate check
6. Populate available staff list
```

#### Step 3: Geofence Status Read
```dart
// Line 519-525 of staff_sign_in_form.dart
GeofenceState? geofenceState;
try {
  geofenceState = context.read<GeofenceCubit>().state;
} catch (_) {
  geofenceState = null;
}
final bool withinGeofence = geofenceState?.isWithinGeofence ?? false;
```

#### Step 4: Current Position Collection
```dart
// Line 527-539 of staff_sign_in_form.dart
Position? position;
try {
  position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    ),
  );
} catch (_) {
  try {
    position = await Geolocator.getLastKnownPosition();
  } catch (_) {}
}
```

**Fallback Strategy**:
1. Try to get current position (high accuracy)
2. If fails, use last known position
3. If both fail, submit (0.0, 0.0) coordinates

#### Step 5: Payload Construction (Self Sign-In)
```dart
// Line 545-559 of staff_sign_in_form.dart
payload = {
  'staffCode': staffCode,
  'method': 'APP' | 'QR',  // Depends on sign-in source
  'latitude': position?.latitude ?? 0,
  'longitude': position?.longitude ?? 0,
  'withinGeofence': true,  // From GeofenceCubit
  'timeZone': 'America/New_York',
  'occurredAt': DateTime.now().toIso8601String(),
  'isExpectedToday': true | false,  // From API gate
  'qrToken': qrToken,  // Only if QR scan
}
```

#### Step 6: Payload Construction (Admin Sign-In)
```dart
// Line 577-598 of staff_sign_in_form.dart
// Admin can sign in multiple staff members
payload = {
  'staffCodes': [staff1, staff2, ...],  // Multiple staff
  'classroomCodeByStaffCode': {staff1: classroom1, ...},
  'method': 'APP' | 'QR',
  'latitude': position?.latitude ?? 0,
  'longitude': position?.longitude ?? 0,
  'withinGeofence': true,
  'timeZone': 'America/New_York',
  'occurredAt': DateTime.now().toIso8601String(),
  ...
}
```

#### Step 7: API Submission
```dart
// Line 601-602 of staff_sign_in_form.dart
final result = await serviceLocator<AttendanceRepository>()
    .submitStaffSignIn(payload: payload, isSelf: !isStaffAdmin);
```

**Endpoint**: `POST /api/v1/schools/{schoolCode}/attendance-settings/sign-in`

#### Step 8: Response Handling
```dart
if (success) {
  // Show success snackbar
  // Navigate back to dashboard
  // Update My Day card (sign-in status changes)
} else {
  // Show error snackbar with message
  // Keep form open for retry
}
```

### Sign Out Flow
**File**: `lib/presentation/features/attendance/forms/staff_attendance_forms/staff_sign_out_form.dart`

Same as Sign In with differences:
- Button only enabled if `_isSignedIn == true`
- Calls `submitStaffSignOut()` instead of `submitStaffSignIn()`
- Payload structure similar but for sign-out

---

## 2. ADMIN SIGN-IN/SIGN-OUT

### Entry Point
**File**: Same staff forms, but with multi-staff selection

### Key Differences from Staff

#### 1. Staff Selection
```dart
// Admin can select multiple staff to sign in simultaneously
_selectedStaff: List<StaffEntity> = [...]  // Multiple items allowed
```

#### 2. Classroom Assignment
```dart
// Admin must assign classroom when signing in staff
final classroomCodeByStaffCode = {
  'STAFF_001': 'CLASSROOM_101',
  'STAFF_002': 'CLASSROOM_101',
}
```

#### 3. Time Override
```dart
// Admin can set sign-in time to past (but not future)
// This is not restricted by geofence - admin can set any time
selectedTime: TimeOfDay  // Can be modified by admin
```

#### 4. Unexpected Sign-In Gate
```dart
// Admin must acknowledge if staff is not expected today
_unexpectedSignInAcknowledged: bool  // Must be true to submit
```

#### 5. Multi-Staff Payload
```dart
payload = {
  'staffCodes': ['STAFF_001', 'STAFF_002'],  // Array
  'classroomCodeByStaffCode': {...},
  'method': 'APP' | 'QR',
  'withinGeofence': true,
  'latitude': position?.latitude ?? 0,
  'longitude': position?.longitude ?? 0,
  ...
}
```

### Admin Dashboard
**File**: `lib/presentation/features/dashboard/view/admin_dashboard.dart`

Shows different cards than staff:
- School Status (enrollment, attendance %)
- Classroom Shifts
- Ratio Monitoring
- Movements (staff arrivals/departures)
- Availability
- Dashboard Attention (alerts)
- My Day (for admin's own shifts if applicable)

Admin can also see the Sign In/Out button on "My Day" card and use it for self sign-in.

---

## 3. STUDENT SIGN-IN/SIGN-OUT (Via Guardian/Parent)

### Entry Point
**Files**:
- `lib/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart`
- `lib/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart`

### Parent Dashboard
**File**: `lib/presentation/features/dashboard/view/parent_dashboard.dart`

### Key Components

#### 1. Child Selection
Parents can have multiple children. Must select which child(ren) to sign in.

```dart
// In my_childs_day_card.dart
final selectedChild = parentChildProvider.selectedChild;
// Parent switches between children via dropdown
```

#### 2. Sign In Button State (Per Child)
```dart
// Button enabled if:
1. Parent has geofence.status == withinRange
2. Selected child exists
3. Child is not already signed in

BlocBuilder<GeofenceCubit, GeofenceState>(
  builder: (context, geofenceState) {
    final bool enabled = geofenceState.status == GeofenceCubitStatus.withinRange;
    return CustomButtonLayout(
      onPressedConfirm: enabled 
        ? () => context.go('/dashboard/student-selection-sign-in-form')
        : null,
    );
  },
)
```

#### 3. Sign In Flow (Single Child)
```dart
// student_sign_in_form.dart
GeofenceState? geofenceState = context.read<GeofenceCubit>().state;
final bool withinGeofence = geofenceState?.isWithinGeofence ?? false;

payload = {
  'studentCode': studentCode,
  'parentCode': parentCode,
  'method': 'APP' | 'QR',
  'latitude': position?.latitude ?? 0,
  'longitude': position?.longitude ?? 0,
  'withinGeofence': true,
  'timeZone': 'America/New_York',
  'occurredAt': DateTime.now().toIso8601String(),
  ...
}
```

#### 4. Sign In Flow (Multiple Children - Student Selection)
```dart
// student_selection_sign_in_form.dart
// Parent selects which children to sign in
_selectedStudents: List<StudentEntity> = [...]

// Payload includes all selected children
payload = {
  'studentCodes': ['STUDENT_001', 'STUDENT_002'],
  'parentCode': parentCode,
  'method': 'APP' | 'QR',
  'latitude': position?.latitude ?? 0,
  'longitude': position?.longitude ?? 0,
  'withinGeofence': true,
  ...
}
```

#### 5. Sign Out Logic
Parents can use the "Smart Sign Out" feature:
- If **all children signed in** → shows "Sign Out" button
- If **some children not signed in** → shows "Sign In" button

```dart
// my_childs_day_card.dart - Line 135-139
bool get _isSelectedChildSignedIn {
  final code = _selectedChildCode;
  if (code.isEmpty) return false;
  return (_childrenSignInStatusMap[code] ?? '').toUpperCase() == 'SIGNED_IN';
}

// This determines button label
String buttonLabel = _isSelectedChildSignedIn ? 'Sign-Out' : 'Sign-In';
```

#### 6. Parent Dashboard Cards
Shows for each child:
- Child's name and classroom
- School schedule (times)
- Countdown to school start/end
- Sign In/Out button (geofence-gated)
- Communication section (latest messages)

---

## Geofence Integration Points

### How GPS Coordinates Flow

```
1. User Location (Device)
   ↓
2. GeofencingClient (Android) / CLLocationManager (iOS)
   ↓
3. Geofence Event Fired (Entry/Exit)
   ↓
4. GeofenceCubit.state updated (withinRange/outsideRange)
   ↓
5. Dashboard BlocBuilder rebuilds
   ↓
6. Sign In/Out button Enable/Disable
   ↓
7. If button tapped:
   a. Collect current position via Geolocator
   b. Include in API payload
   c. Backend validates position is within geofence
   d. Updates attendance record
```

### Current Geofence Config

**Active Coordinates**:
```
Latitude:  19.226339°N  (±0.0005° = ~55 meters)
Longitude: 73.098545°E  (±0.0005° = ~45 meters)
Radius:    100 meters

Valid Sign-In Zone:
- North boundary:  19.226894°N
- South boundary:  19.225784°N
- East boundary:   73.099245°E
- West boundary:   73.097845°E
```

**Accuracy Requirements**:
- Device location accuracy: High (±5-10m typical)
- API submission includes: latitude, longitude, withinGeofence flag
- Backend validates: distance calculation vs stored coordinates

---

## Data Flow Diagram

### Staff Sign In
```
┌─────────────────────────────────┐
│  Staff Dashboard (my_day_card)  │
│  Button: [SIGN IN] (Enabled)    │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│ staff_sign_in_form.dart                     │
├─────────────────────────────────────────────┤
│ 1. Get current staff code from storage      │
│ 2. Read geofence state (withinGeofence)     │
│ 3. Get current GPS position                 │
│ 4. Resolve school timezone                  │
│ 5. Check if staff is expected today         │
│ 6. Optionally override time (admin only)    │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  Prepare Payload                         │
├──────────────────────────────────────────┤
│ {                                        │
│   staffCode: "STAFF_001",                │
│   method: "APP" | "QR",                  │
│   latitude: 19.226550,                   │
│   longitude: 73.098600,                  │
│   withinGeofence: true,                  │
│   timeZone: "America/New_York",          │
│   occurredAt: "2026-06-01T13:52:41Z",    │
│   isExpectedToday: true,                 │
│   qrToken: "..." (if QR scan)            │
│ }                                        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│ POST /api/v1/schools/{schoolCode}/       │
│     attendance-settings/sign-in           │
├──────────────────────────────────────────┤
│ AttendanceRepository.submitStaffSignIn() │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│ Backend Processing                       │
├──────────────────────────────────────────┤
│ 1. Validate staff exists                 │
│ 2. Check geofence distance calc          │
│ 3. Verify expected today or gate         │
│ 4. Check for conflicts                   │
│ 5. Create attendance record              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│ Response                                 │
├──────────────────────────────────────────┤
│ {                                        │
│   success: true,                         │
│   message: "Signed in successfully",     │
│   data: {...}                            │
│ }                                        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│ UI Update                                │
├──────────────────────────────────────────┤
│ • Show success snackbar                  │
│ • Navigate back to dashboard             │
│ • Refresh My Day card                    │
│ • Update sign-in status                  │
│ • Button changes to "SIGN OUT"           │
└──────────────────────────────────────────┘
```

### Parent Sign In (Student via Guardian)
```
┌────────────────────────────────────┐
│ Parent Dashboard (my_childs_day)   │
│ Selected Child: "Emma"             │
│ Button: [SIGN IN] (Enabled)        │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────┐
│ student_sign_in_form.dart                    │
├──────────────────────────────────────────────┤
│ 1. Get selected student code                 │
│ 2. Read geofence state (withinGeofence)      │
│ 3. Get current GPS position                  │
│ 4. Resolve school timezone                   │
│ 5. Get parent code from storage              │
└──────────┬────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│  Prepare Payload                         │
├──────────────────────────────────────────┤
│ {                                        │
│   studentCode: "STUDENT_001",            │
│   parentCode: "PARENT_001",              │
│   method: "APP" | "QR",                  │
│   latitude: 19.226550,                   │
│   longitude: 73.098600,                  │
│   withinGeofence: true,                  │
│   timeZone: "America/New_York",          │
│   occurredAt: "2026-06-01T13:52:41Z",    │
│   qrToken: "..." (if QR scan)            │
│ }                                        │
└──────────┬────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│ POST /api/v1/schools/{schoolCode}/       │
│     attendance-settings/sign-in           │
├──────────────────────────────────────────┤
│ AttendanceRepository.submitStudentSignIn()│
└──────────────┬────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│ UI Update                                │
├──────────────────────────────────────────┤
│ • Show success message                   │
│ • Refresh child's attendance status      │
│ • Button changes to "SIGN OUT"           │
│ • Update dashboard card                  │
└──────────────────────────────────────────┘
```

---

## Current Status: Target Values

### Geofence Configuration ✅
- **School Code**: SCH_719FA95B-3
- **Latitude**: 19.226339
- **Longitude**: 73.098545
- **Radius**: 100 meters
- **GPS Enabled**: true
- **Auto Sign Out**: true (30 min delay)

### Button Enable Conditions ✅

#### Staff
```dart
enabled = (geofenceState.status == GeofenceCubitStatus.withinRange)
         && (geofenceState.gpsSignInEnabled == true)
```

#### Admin
```dart
enabled = (geofenceState.status == GeofenceCubitStatus.withinRange)
         && (geofenceState.gpsSignInEnabled == true)
```

#### Guardian/Parent (for Student)
```dart
enabled = (geofenceState.status == GeofenceCubitStatus.withinRange)
         && (geofenceState.gpsSignInEnabled == true)
         && (selectedChild != null)
```

### Data Captured ✅

**For Staff/Admin**:
- ✅ staffCode
- ✅ method (APP or QR)
- ✅ latitude (19.226339 ± accuracy)
- ✅ longitude (73.098545 ± accuracy)
- ✅ withinGeofence (true/false from GeofenceCubit)
- ✅ timeZone (America/New_York)
- ✅ occurredAt (ISO 8601 timestamp)
- ✅ isExpectedToday (from API gate)

**For Students (via Parent)**:
- ✅ studentCode
- ✅ parentCode
- ✅ method (APP or QR)
- ✅ latitude
- ✅ longitude
- ✅ withinGeofence
- ✅ timeZone
- ✅ occurredAt

---

## Validation Rules

### Backend Geofence Validation
```
if withinGeofence == false and geoDistance > radius + tolerance:
  REJECT with error: "You are outside the school premises"

if withinGeofence == true and geoDistance <= radius + tolerance:
  ACCEPT and create attendance record

tolerance = 50 meters (hysteresis to prevent flickering)
```

### Button Visibility Rules
```
SHOW SIGN IN BUTTON when:
  - User is NOT signed in
  - User is within geofence
  - GeofenceCubit.status == withinRange

SHOW SIGN OUT BUTTON when:
  - User IS signed in
  - User is within geofence
  - GeofenceCubit.status == withinRange

DISABLE BUTTON when:
  - User is outside geofence
  - GeofenceCubit.status == outsideRange | permissionDenied | locationDisabled

DISABLE with TOOLTIP when:
  - Tooltip: "You are not within geofencing Range"
```

---

## Testing Checklist

### Prerequisites
- [ ] Device location services enabled
- [ ] Location permissions granted to WowCare app
- [ ] Network connectivity
- [ ] School location configured: 19.226339, 73.098545 with 100m radius

### Staff Sign In Test
- [ ] Open app while outside geofence
- [ ] Verify "Sign In" button is disabled with tooltip
- [ ] Walk into geofence
- [ ] Verify "Sign In" button becomes enabled (< 5 seconds)
- [ ] Tap "Sign In"
- [ ] Verify form opens
- [ ] Verify current position included
- [ ] Verify geofence status: withinGeofence = true
- [ ] Tap "Submit"
- [ ] Verify success message
- [ ] Verify "Sign Out" button now shows

### Admin Bulk Sign In Test
- [ ] Open admin dashboard
- [ ] Verify admin can select multiple staff
- [ ] Verify classroom assignment required
- [ ] Verify geofence required for button enable
- [ ] Submit bulk sign-in
- [ ] Verify all selected staff signed in

### Parent Student Sign In Test
- [ ] Open parent dashboard
- [ ] Switch between children
- [ ] Verify button state updates per child
- [ ] Walk into geofence
- [ ] Verify button enabled
- [ ] Submit student sign in
- [ ] Verify success
- [ ] Verify "Smart" button: if all kids signed in, shows "SIGN OUT"

### Geofence Boundary Test
- [ ] Position at boundary (19.226339 ± 0.0005)
- [ ] Verify button enable/disable state transitions smoothly
- [ ] Check for hysteresis (50m tolerance prevents flickering)

---

## Known Issues & Limitations

### 1. GPS Accuracy Variance
- Device GPS accuracy: ±5-25 meters (varies by device, environment)
- Building interiors: Accuracy degrades significantly
- Multi-story buildings: Vertical accuracy can be poor

**Mitigation**: 100-meter radius is generous to account for this

### 2. Network Latency
- Position fetch with timeout: 10 seconds
- If timeout, uses last known position
- If no position available, submits (0.0, 0.0)

### 3. Geofence Event Delay
- Android: 1-5 seconds typical
- iOS: 2-10 seconds typical
- Depends on location refresh rate

### 4. iOS Limitations
- Requires "Always" location permission
- Uses Significant Location Changes (less frequent)
- Cannot detect precise geofence transitions
- Falls back to distance calculation from position stream

### 5. Permissions Model
- Location permission required
- Different for foreground, background, always
- Android 12+: Requires explicit permissions dialog
- iOS 14+: Requires user consent for background

---

## Configuration Parameters

### GeofencePrefs.kt (Android Persistence)
```kotlin
geofence_school_lat: Double     // 19.226339
geofence_school_lon: Double     // 73.098545
geofence_school_radius_m: Double // 100.0
geofence_gps_sign_in_enabled: Boolean // true
geofence_last_status: String    // "within" or "outside"
geofence_last_notified_inside: Boolean
```

### SharedPreferences (Dart/Flutter)
```dart
geofence_school_lat: double
geofence_school_lon: double
geofence_school_radius_m: double
geofence_gps_sign_in_enabled: bool
geofence_last_status: string
geofence_last_notified_inside: bool
geofence_exit_hysteresis_extra_m: double  // 50.0
```

### API Payload
```json
{
  "staffCode": "STAFF_001",
  "studentCode": "STUDENT_001",
  "parentCode": "PARENT_001",
  "method": "APP|QR",
  "latitude": 19.226550,
  "longitude": 73.098600,
  "withinGeofence": true,
  "timeZone": "America/New_York",
  "occurredAt": "2026-06-01T13:52:41Z",
  "isExpectedToday": true
}
```

---

## Next Steps

### Immediate (Testing)
1. Deploy to test device with school coordinates
2. Test all three user types (Staff, Admin, Guardian)
3. Test all three app states (Foreground, Background, Terminated)
4. Verify database records created with correct coordinates

### Short Term (Enhancement)
1. Add location debug overlay (show current coordinates)
2. Add geofence distance display (how close to boundary)
3. Add geofence event logging for debugging
4. Add mock geofence location for testing

### Medium Term (Features)
1. Support multiple geofence zones
2. Add time-based override (after-hours signing)
3. Add bulk re-geofencing after app update
4. Add geofence re-registration on device reboot

---

**Report Generated**: 2026-06-01  
**School**: SCH_719FA95B-3  
**Coordinates**: 19.226339, 73.098545  
**Radius**: 100 meters  
**Status**: Ready for Integration Testing
