# GPS Geofencing System - Implementation Flow Diagram

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         WOWCARE GEOFENCING SYSTEM                   │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                           ANDROID LAYER                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────┐      ┌──────────────────────────┐    │
│  │ GooglePlayServices       │      │ Android Framework        │    │
│  │ GeofencingClient         │◄────►│ LocationManager          │    │
│  │ (GPS Location Service)   │      │ (System Service)         │    │
│  └──────────────────────────┘      └──────────────────────────┘    │
│         ▲                                   ▲                        │
│         │                                   │                        │
│         └───────────────────┬───────────────┘                        │
│                             │                                        │
│                    ┌────────▼────────┐                               │
│                    │ GeofenceBootRec │ (Restarts geofence            │
│                    │ eiver.kt        │  after device reboot)         │
│                    └────────┬────────┘                               │
│                             │                                        │
│                    ┌────────▼────────────────┐                       │
│                    │ GeofenceBroadcastRec.kt │ (Receives entry/exit) │
│                    │ - Updates SharedPrefs   │                       │
│                    │ - Emits to Flutter      │                       │
│                    └────────┬────────────────┘                       │
│                             │                                        │
│                    ┌────────▼────────────────┐                       │
│                    │ GeofencePlugin.kt       │ (MethodChannel bridge)│
│                    │ - EventChannel sink     │                       │
│                    │ - Updates school loc    │                       │
│                    │ - Query geofence status │                       │
│                    └────────┬────────────────┘                       │
│                             │                                        │
│                    ┌────────▼────────────────┐                       │
│                    │ GeofencePrefs.kt        │ (Persistent storage)  │
│                    │ - Last known state      │                       │
│                    │ - School coordinates    │                       │
│                    │ - Geofence radius       │                       │
│                    └────────┬────────────────┘                       │
│                             │                                        │
│                        Android SharedPrefs                           │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                               │
                      EventChannel Stream
                         (Native Bridge)
                               │
┌──────────────────────────────▼──────────────────────────────────────┐
│                          FLUTTER LAYER                               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    GeofenceCubit                               │ │
│  ├────────────────────────────────────────────────────────────────┤ │
│  │                                                                │ │
│  │  initForSchool(schoolCode)  ◄── Entry Point (Dashboard)      │ │
│  │         │                                                      │ │
│  │         ├─► _checkAndStartMonitoring()                        │ │
│  │         │    ├─► Check location permissions                   │ │
│  │         │    ├─► Fetch school location (API)                  │ │
│  │         │    ├─► Persist config to SharedPrefs               │ │
│  │         │    ├─► _updateNativeGeofence()  (Register)         │ │
│  │         │    │    └─► GeofencePlugin.updateSchoolLocation()  │ │
│  │         │    │         └─► Android native geofence register   │ │
│  │         │    ├─► _startNativeEvents()  (Listen for events)    │ │
│  │         │    │    └─► EventChannel.receiveBroadcastStream()   │ │
│  │         │    │         └─► On geofence event:                 │ │
│  │         │    │             1. Emit state.copyWith(status)     │ │
│  │         │    │             2. _triggerNotificationIfNeeded()  │ │
│  │         │    └─► _startStream()  (iOS location stream)        │ │
│  │         │                                                      │ │
│  │         └─► Emit GeofenceState via Bloc                       │ │
│  │              └─► Dashboard BlocBuilder rebuilds               │ │
│  │                   └─► Sign In button shows enabled/disabled   │ │
│  │                                                                │ │
│  │  Core State Properties:                                        │ │
│  │  - status: GeofenceCubitStatus                                │ │
│  │    * initial                                                  │ │
│  │    * checkingPermission                                       │ │
│  │    * permissionDenied                                         │ │
│  │    * locationDisabled                                         │ │
│  │    * fetchingSchoolLocation                                   │ │
│  │    * checking                                                 │ │
│  │    * withinRange      ◄─── Sign In button ENABLED             │ │
│  │    * outsideRange     ◄─── Sign In button DISABLED            │ │
│  │    * gpsDisabledByAdmin                                       │ │
│  │    * error                                                    │ │
│  │                                                                │ │
│  │  - schoolCode: String                                         │ │
│  │  - gpsSignInEnabled: bool                                     │ │
│  │  - radiusMeters: double                                       │ │
│  │  - distanceMeters: double?  (iOS only)                        │ │
│  │                                                                │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                             ▲                                        │
│                             │                                        │
│            ┌────────────────┼─────────────────┐                      │
│            │                │                 │                      │
│  ┌─────────▼────┐  ┌────────▼──────┐  ┌──────▼────────┐             │
│  │  MyDayCard   │  │ MyChildsDayCard│  │ Admin/Staff   │             │
│  │  (Staff)     │  │ (Parent)       │  │ Dashboard     │             │
│  ├──────────────┤  ├────────────────┤  ├───────────────┤             │
│  │ BlocBuilder< │  │ BlocBuilder<   │  │ BlocBuilder<  │             │
│  │  Geofence>   │  │  Geofence>     │  │  Geofence>    │             │
│  │              │  │                │  │               │             │
│  │ Status Check:│  │ Status Check:  │  │ Status Check: │             │
│  │ withinRange? │  │ withinRange?   │  │ withinRange?  │             │
│  │   ├─► Enabled│  │   ├─► Enabled  │  │   ├─► Enabled │             │
│  │   └─► Disabled│  │   └─► Disabled│  │   └─► Disabled│             │
│  │              │  │                │  │               │             │
│  │ Listeners:   │  │ Listeners:     │  │ Listeners:    │             │
│  │ • On entry   │  │ • On entry     │  │ • Show popup  │             │
│  │   show popup │  │   show popup   │  │ • Status msgs │             │
│  │ • On exit    │  │ • On exit      │  │               │             │
│  │   reset guard│  │   reset guard  │  │               │             │
│  └──────────────┘  └────────────────┘  └───────────────┘             │
│          │                │                     │                     │
│          └────────────────┼─────────────────────┘                     │
│                           │                                           │
│              ┌────────────▼────────────┐                              │
│              │GeofenceNotificationSvc  │                              │
│              ├─────────────────────────┤                              │
│              │ showEnteredZone()       │                              │
│              │ showExitedZone()        │                              │
│              │ showCustom()            │                              │
│              │                         │                              │
│              │ Uses:                   │                              │
│              │ flutter_local_          │                              │
│              │ notifications plugin    │                              │
│              └────────────┬────────────┘                              │
│                           │                                           │
│                    ┌──────▼──────┐                                    │
│                    │ Notification│                                    │
│                    │ Center/Tray │                                    │
│                    └─────────────┘                                    │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Sequence Diagram: User Enters Geofence (App Open)

```
User                 Device                Android                Flutter
 │                    │                     │                       │
 │  Walk into         │                     │                       │
 │  geofence          │                     │                       │
 ├───────────────────►│                     │                       │
 │                    │ LocationManager     │                       │
 │                    │ detects entry       │                       │
 │                    ├────────────────────►│                       │
 │                    │                     │ GeofencingClient      │
 │                    │                     │ fires ENTER event     │
 │                    │                     ├──────────────────────►│
 │                    │                     │ GeofenceBroadcast    │
 │                    │                     │ Receiver.onReceive()  │
 │                    │                     ├──────────────────────►│
 │                    │                     │ Update last_inside    │
 │                    │                     │ SharedPrefs: true     │
 │                    │                     │                       │
 │                    │                     │ EventChannel.emit()   │
 │                    │                     ├──────────────────────►│
 │                    │                     │                    _startNativeEvents()
 │                    │                     │                    receives { isInside: true }
 │                    │                     │                       │
 │                    │                     │◄──────────────────────┤
 │                    │                     │ Update GeofenceState  │
 │                    │                     │ status = withinRange  │
 │                    │                     │                       │
 │                    │◄────────────────────┤ Emit new state        │
 │                    │                     │ to BlocListeners      │
 │                    │                     │                       │
 │ Notification:      │                     │ Trigger notification  │
 │ "Attendance        │                     │ if state changed      │
 │  Available"        │                     │                       │
 │◄────────────────────────────────────────┤ Show notification     │
 │                    │                     │ (Android & Flutter)   │
 │ Sign In button:    │                     │                       │
 │ [ENABLED]          │                     │ BlocBuilder rebuilds  │
 │                    │                     │ Sign In button enabled│
 │◄────────────────────────────────────────────────────────────────┤
 │                    │                     │                       │
```

---

## Sequence Diagram: User Enters Geofence (App Backgrounded)

```
User                 Device                Android                Flutter          SharedPrefs
 │                    │                     │                       │                 │
 │  Walk into         │                     │                       │                 │
 │  geofence          │                     │                       │                 │
 ├───────────────────►│                     │                       │                 │
 │                    │ GeofencingClient    │                       │                 │
 │                    │ fires ENTER event   │                       │                 │
 │                    ├────────────────────►│                       │                 │
 │                    │                     │ GeofenceBroadcast    │                 │
 │                    │                     │ Receiver.onReceive()  │                 │
 │                    │                     ├──────────────────────►│                 │
 │                    │                     │ IMPORTANT: Still      │                 │
 │                    │                     │ fires even if app     │                 │
 │                    │                     │ is backgrounded/killed│
 │                    │                     │                       │                 │
 │ Notification:      │                     │ Update last_inside    │                 │
 │ "Attendance        │                     │ SharedPrefs: true     │                 │
 │  Available"        │                     ├──────────────────────────────────────► │
 │ (in notification   │                     │                       │                 │
 │  center/tray)      │                     │ EventChannel.emit()   │                 │
 │◄────────────────────────────────────────►│ (if Flutter running)  │                 │
 │                    │                     │                       │                 │
 │                    │                     │                       │                 │
 │ [Later: User       │                     │                       │                 │
 │  opens app]        │                     │                       │                 │
 │                    │                     │                       │                 │
 │ Tap notification   │                     │                       │                 │
 │ OR open app        │                     │                       │                 │
 ├───────────────────►│                     │                       │                 │
 │                    │                     │                       │                 │
 │                    │ App launched        │                       │                 │
 │                    ├─────────────────────────────────────────►   │                 │
 │                    │                     │                 GeofenceCubit           │
 │                    │                     │                 initForSchool()         │
 │                    │                     │                 ├─► _restoreLastKnown  │
 │                    │                     │                 │    Status()           │
 │                    │                     │                 │    ├─► read from Pref │
 │                    │                     │                 │    ├─► last_inside    │
 │                    │                     │                 │    │    = true         │
 │ Sign In button:    │                     │                 │    └─► Restore status │
 │ [ENABLED]          │                     │                 │        withinRange    │
 │ (IMMEDIATE!)       │◄───────────────────────────────────────────────────────────┤│
 │                    │                     │                 └─► Emit state         ││
 │                    │                     │                     BlocBuilder        ││
 │                    │                     │                     rebuilds           ││
 │                    │                     │                                        ││
```

---

## Sequence Diagram: User Enters Geofence (App Killed)

```
User                 Device                Android                Flutter    SharedPrefs
 │                    │                     │                       │          │
 │  Walk into         │                     │                       │          │
 │  geofence          │                     │                       │          │
 │ (App is killed)    │                     │                       │          │
 ├───────────────────►│                     │                       │          │
 │                    │ GeofencingClient    │                       │          │
 │                    │ fires ENTER event   │                       │          │
 │                    ├────────────────────►│                       │          │
 │                    │                     │ GeofenceBroadcast    │          │
 │                    │                     │ Receiver (manifested) │          │
 │                    │                     │ App process started   │          │
 │                    │                     │ onReceive() called    │          │
 │                    │                     │                       │          │
 │ Notification:      │                     │ Update last_inside    │          │
 │ "Attendance        │                     │ SharedPrefs: true     │          │
 │  Available"        │                     ├────────────────────────────────►│
 │ (in notification   │                     │                       │          │
 │  tray/center)      │                     │ EventChannel.emit()   │          │
 │◄────────────────────────────────────────►│ (Flutter isolate may  │          │
 │                    │                     │  not be running yet)  │          │
 │                    │                     │                       │          │
 │                    │                     │                       │          │
 │ [Later: User taps  │                     │                       │          │
 │  notification or   │                     │                       │          │
 │  opens app]        │                     │                       │          │
 │                    │                     │                       │          │
 │ Tap notification   │                     │                       │          │
 │ OR open app        │                     │                       │          │
 ├───────────────────►│                     │                       │          │
 │                    │                     │                       │          │
 │                    │ Main app activity   │                       │          │
 │                    │ onCreate()          │                       │          │
 │                    ├──────────────────────────────────────────────────────►│
 │                    │                     │                       │          │
 │                    │                     │                       │ Flutter  │
 │                    │                     │                       │ engine   │
 │                    │                     │                       │ starts   │
 │                    │                     │                       │          │
 │                    │                     │                       │ GeofenceC│
 │                    │                     │                       │ ubit      │
 │                    │                     │                       │ init...() │
 │ Sign In button:    │                     │                       ├─►_restore│
 │ [ENABLED]          │                     │                       │  Last    │
 │ (IMMEDIATE!)       │◄──────────────────────────────────────────────Known   │
 │                    │                     │                       │ Status() │
 │                    │                     │                       │  reads   │
 │                    │                     │                       │  SharedP │
 │                    │                     │                       │  ref:    │
 │                    │                     │                       │  last_   │
 │                    │                     │                       │  inside= │
 │                    │                     │                       │  true    │
 │                    │                     │                       │          │
 │                    │                     │                       │ Emit     │
 │                    │                     │                       │ withinRng│
 │                    │                     │                       │ BlocBldr │
 │                    │                     │                       │ rebuilds │
 │                    │                     │                       │          │
```

---

## State Transition Diagram

```
                        ┌─────────────────┐
                        │     INITIAL     │
                        └────────┬────────┘
                                 │
                    initForSchool(schoolCode)
                                 │
                                 ▼
                 ┌──────────────────────────┐
                 │CHECKING_PERMISSION       │
                 │ (Verify location access) │
                 └────────┬─────────────────┘
                          │
            ┌─────────────┼──────────────────┐
            │             │                  │
      Granted       Denied/Need      Location
            │        Request               Disabled
            │             │                  │
            ▼             ▼                  ▼
     ┌────────────┐ ┌──────────────┐  ┌──────────────┐
     │FETCHING_   │ │PERMISSION_   │  │LOCATION_     │
     │SCHOOL_LOC  │ │DENIED        │  │DISABLED      │
     └──────┬─────┘ └──────────────┘  └──────────────┘
            │
     API call to get
     school location
            │
            ▼
     ┌────────────────┐
     │  CHECKING      │
     │ (Waiting for   │
     │  location fix) │
     └────────┬───────┘
              │
         ┌────┴────┐
         │          │
    withinRange  outsideRange
         │          │
         ▼          ▼
    ┌────────┐  ┌────────────┐
    │WITHIN_ │  │OUTSIDE_    │
    │RANGE   │  │RANGE       │
    └────┬───┘  └──────┬─────┘
         │             │
         │◄────────────┤ User walks into/out of geofence
         │             │
    ◄─────────────────►  (Continuous cycling)
         │
    User walks out
         │
         ▼
    ┌────────────┐
    │OUTSIDE_    │
    │RANGE       │
    └────────────┘

         OR

    GPS Disabled
    by Admin
         │
         ▼
    ┌─────────────────┐
    │GPS_DISABLED_BY_ │
    │ADMIN            │
    └─────────────────┘
```

---

## Key Implementation Details

### 1. **Initialization Sequence (Critical Path)**

```
Dashboard.initState()
  └─► addPostFrameCallback(
      └─► _initGeofence() [AWAIT]
          └─► getSchoolCode()
          └─► GeofenceCubit.initForSchool() [AWAIT]
              └─► _checkAndStartMonitoring()
                  ├─► Check permissions
                  ├─► getSchoolLocation() [API call]
                  ├─► Persist config
                  ├─► _updateNativeGeofence() [Register geofence]
                  │   └─► GeofencePlugin.updateSchoolLocation()
                  │       └─► GeofencingClient.addGeofences()
                  │
                  ├─► _startNativeEvents() [iOS/Android]
                  │   └─► receiveBroadcastStream().listen()
                  │       └─► On event: emit state + notify
                  │
                  ├─► _restoreLastKnownStatus()
                  │   └─► Read from SharedPrefs
                  │
                  └─► Emit GeofenceState
                      └─► BlocBuilder rebuilds
                          └─► Sign In button updated
```

### 2. **Geofence Event Handling (Background)**

```
Android Geofence Event (even if app killed)
  └─► GeofenceBroadcastReceiver.onReceive()
      ├─► Extract geofence transition (ENTER/EXIT)
      ├─► Check: hasStateChanged()?
      ├─► Update SharedPrefs (last_inside)
      └─► GeofenceEventStreamHandler.emit(isInside)
          └─► EventChannel.EventSink.success(mapOf("isInside" to isInside))
              └─► [If Flutter running]
                  └─► _startNativeEvents() listener receives event
                      ├─► Update GeofenceState
                      └─► _triggerNotificationIfNeeded()
                          └─► GeofenceNotificationService.show()
```

### 3. **State Restoration (App Cold Start)**

```
App launches while inside geofence
  └─► GeofenceCubit.initForSchool()
      └─► _restoreLastKnownStatus()
          └─► SharedPreferences.getString("geofence_last_status")
              ├─► If "within": return GeofenceCubitStatus.withinRange
              └─► If "outside": return GeofenceCubitStatus.outsideRange
      └─► Emit restored state immediately
          └─► BlocBuilder rebuilds
              └─► Sign In button enabled [NO DELAY]
      └─► Then call _startNativeEvents() to listen for future updates
```

---

## Critical: Re-Initialization Guard

```dart
// Prevent re-initialization of same school
if (state.schoolCode == schoolCode &&
    (state.status == withinRange ||
     state.status == outsideRange ||
     state.status == gpsDisabledByAdmin ||
     state.status == checking ||
     state.status == fetchingSchoolLocation)) {  // ← KEY: Don't re-init while fetching
  return;  // Skip, already initialized
}
```

This guard prevents:
- Multiple dashboard widgets from re-initializing simultaneously
- Race conditions from API calls
- Redundant geofence registrations
- Stale state from partial initialization

---

## Testing Flow

```
Test Case 1: Foreground Entry
Dashboard Open ──► addPostFrameCallback ──► initForSchool() [AWAIT]
  └─► Permissions check ──► School location fetch ──► Register geofence
      ────► _startNativeEvents() listening
           User enters geofence ──► GeofenceEvent fires
           └─► State update (withinRange) ──► Button enabled ✓

Test Case 2: Background Entry
App in background ──► User enters geofence
  └─► GeofenceEvent fires ──► Notification shown ✓
      User opens app ──► initForSchool() ──► _restoreLastKnownStatus()
      └─► Read SharedPrefs (within) ──► Button enabled immediately ✓

Test Case 3: Killed App Entry
App killed ──► User enters geofence
  └─► GeofenceEvent fires ──► System starts app process
      └─► Notification shown ✓
      User opens app ──► initForSchool() ──► _restoreLastKnownStatus()
      └─► Read SharedPrefs (within) ──► Button enabled immediately ✓
```

---

**Diagram Generated**: 2026-06-01
**System Status**: Production Ready
