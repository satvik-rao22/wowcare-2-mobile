# GPS-Based Geofencing System - Implementation Fix

## Root Cause Analysis

The geofencing system had multiple issues preventing reliable operation:

### 1. **Async Initialization Race Condition** (CRITICAL)
- **Issue**: Dashboard cards called `initForSchool()` with `unawaited()`, causing UI to render before initialization completed
- **Impact**: Sign In/Out buttons appeared disabled even when user was inside geofence because `GeofenceState` hadn't been initialized yet
- **Root Cause**: Asynchronous initialization was not awaited, so the cubit emitted initial state before completing setup

### 2. **Duplicate Geofence Initialization**
- **Issue**: Geofence was being initialized from multiple sources:
  - `StaffDashboard.initState()`
  - `ParentDashboard.initState()`
  - `AdminDashboard.initState()`
  - `MyDayCard.didChangeDependencies()`
  - `MyChildsDayCard.didChangeDependencies()`
- **Impact**: Race conditions, stale state, unnecessary API calls
- **Root Cause**: No guard against re-initialization of the same school

### 3. **Notification System Conflicts**
- **Issue**: Both Android native code and Flutter were showing notifications
  - `GeofenceBroadcastReceiver` → `GeofenceNotifications.show()`
  - `GeofenceCubit` → `GeofenceNotificationService.show()`
- **Impact**: Duplicate or missing notifications
- **Root Cause**: Notifications implemented at two different layers

### 4. **Native Event Stream Not Triggering Notifications**
- **Issue**: Android broadcast receiver emitted events but Flutter didn't trigger notifications
- **Impact**: User never saw "You've entered geofence" notification in background
- **Root Cause**: `_startNativeEvents()` emitted state but didn't call `_triggerNotificationIfNeeded()`

### 5. **Dashboard State Not Persisting Across App Restarts**
- **Issue**: When app restarted, geofence state wasn't available until first location update
- **Impact**: Buttons appeared disabled on app startup even if user was inside geofence
- **Root Cause**: Restoration logic was correct but initialization race conditions prevented it from working

---

## Implementation Changes

### Android Changes

#### 1. `GeofencePlugin.kt`
- **Added**: `getGeofenceStatus()` method to query current geofence state
- **Purpose**: Allows Flutter to check native state without waiting for location updates

```kotlin
private fun handleGetGeofenceStatus(result: MethodChannel.Result) {
    val config = GeofencePrefs.readConfig(appContext)
    val isInside = GeofencePrefs.getLastInside(appContext)
    result.success(mapOf(
        "isInside" to isInside,
        // ... other fields
    ))
}
```

#### 2. `GeofencePrefs.kt`
- **Added**: `getLastInside()` getter method
- **Purpose**: Retrieve last known geofence state from persistent storage

#### 3. `GeofenceBroadcastReceiver.kt`
- **Removed**: Direct Android notification via `GeofenceNotifications.show()`
- **Changed**: Now only updates state and emits to Flutter event stream
- **Purpose**: Single source of truth for notifications (Flutter layer)

```kotlin
// Removed:
// GeofenceNotifications.ensureChannel(context)
// GeofenceNotifications.show(context, isInside)

// Keep only:
GeofenceEventStreamHandler.emit(isInside)
```

---

### Flutter Changes

#### 1. `geofence_cubit.dart`

**a) Fixed `_startNativeEvents()` to trigger notifications:**
```dart
void _startNativeEvents() {
  if (!Platform.isAndroid) return;
  _nativeSubscription = _nativeGeofenceEvents.receiveBroadcastStream().listen((event) {
    // ... state update
    final newGeofenceStatus = isInside ? GeofenceStatus.within : GeofenceStatus.outside;
    _triggerNotificationIfNeeded(newGeofenceStatus);  // NEW
  });
}
```

**b) Fixed `_triggerNotificationIfNeeded()` to await SharedPreferences:**
```dart
unawaited(
  SharedPreferences.getInstance()
      .then((prefs) async {
        await prefs.setString(_prefsLastGeofenceStatusKey, newStatus.name);  // Properly await
        await prefs.setBool(_prefsLastNotifiedInsideKey, newStatus == GeofenceStatus.within);
      })
      .catchError((_) {}),
);
```

**c) Improved `initForSchool()` re-initialization guard:**
```dart
// Added fetchingSchoolLocation to prevent re-init while already initializing
if (state.schoolCode == schoolCode &&
    (state.status == GeofenceCubitStatus.withinRange ||
        state.status == GeofenceCubitStatus.outsideRange ||
        state.status == GeofenceCubitStatus.gpsDisabledByAdmin ||
        state.status == GeofenceCubitStatus.checking ||
        state.status == GeofenceCubitStatus.fetchingSchoolLocation)) {  // NEW
  return;
}
```

#### 2. Dashboard Cards - `my_day_card.dart` & `my_childs_day_card.dart`

**Fixed async initialization to properly await:**
```dart
// BEFORE:
context.read<GeofenceCubit>().initForSchool(schoolCode: schoolCode);  // Not awaited

// AFTER:
await context.read<GeofenceCubit>().initForSchool(schoolCode: schoolCode);  // Properly awaited
```

**Removed duplicate initialization in MyChildsDayCard:**
```dart
// Removed:
if (s.schoolCode.isNotEmpty) {
  unawaited(context.read<GeofenceCubit>().initForSchool(schoolCode: s.schoolCode));
}

// Now: Geofence is initialized in didChangeDependencies, don't reinitialize
```

#### 3. Dashboard Screens - `staff_dashboard.dart`, `parent_dashboard.dart`, `admin_dashboard.dart`

**Fixed initialization sequencing using `addPostFrameCallback()`:**
```dart
@override
void initState() {
  // ... initialize cubits
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initGeofence());  // Fire-and-forget after frame
    // ... other init calls
  });
}

Future<void> _initGeofence() async {
  final storage = serviceLocator<StorageService>();
  final schoolCode = await storage.getString(StorageKeys.schoolCode);
  if (schoolCode != null && schoolCode.isNotEmpty) {
    await _geofenceCubit.initForSchool(schoolCode: schoolCode);  // Properly await
  }
}
```

---

## Expected Behavior After Fix

### Scenario 1: User Enters Geofence (App Open)
1. ✅ Geofence event received by Android `GeofenceBroadcastReceiver`
2. ✅ Event emitted to Flutter via event channel
3. ✅ `_startNativeEvents()` updates `GeofenceState.status = withinRange`
4. ✅ Dashboard BlocBuilder rebuilds with new state
5. ✅ Sign In button becomes enabled
6. ✅ Notification shown by Flutter's `GeofenceNotificationService`

### Scenario 2: User Enters Geofence (App Backgrounded)
1. ✅ Geofence event received by Android
2. ✅ Event emitted to Flutter event stream (even though app is backgrounded)
3. ✅ Notification shown by native Android receiver → Flutter layer
4. ✅ User opens app
5. ✅ GeofenceCubit restored last known state from SharedPreferences
6. ✅ Sign In button shows enabled immediately
7. ✅ Location stream updates confirm state

### Scenario 3: User Enters Geofence (App Terminated)
1. ✅ Geofence event received by Android
2. ✅ Notification shown by Flutter's `GeofenceNotificationService` when event fires
3. ✅ State persisted to Android SharedPreferences
4. ✅ User opens app
5. ✅ `GeofenceCubit.initForSchool()` called
6. ✅ Last known state restored via `_restoreLastKnownStatus()`
7. ✅ Sign In button shows enabled immediately
8. ✅ Location stream in background updates confirm state

### Scenario 4: User Exits Geofence
1. ✅ Geofence exit event received
2. ✅ `GeofenceState.status = outsideRange`
3. ✅ Dashboard rebuilds
4. ✅ Sign In/Out buttons disabled
5. ✅ Exit notification shown

---

## Files Modified

### Android (Kotlin)
- `android/app/src/main/kotlin/com/wiseowl/wowcareapp/GeofencePlugin.kt`
- `android/app/src/main/kotlin/com/wiseowl/wowcareapp/GeofenceBroadcastReceiver.kt`
- `android/app/src/main/kotlin/com/wiseowl/wowcareapp/GeofencePrefs.kt`
- `android/app/src/main/kotlin/com/wiseowl/wowcareapp/GeofenceBootReceiver.kt` (no changes needed, already correct)

### Flutter (Dart)
- `lib/presentation/features/geofencing/cubit/geofence_cubit.dart`
- `lib/presentation/features/dashboard/view/widgets/my_day_card.dart`
- `lib/presentation/features/dashboard/view/widgets/my_childs_day_card.dart`
- `lib/presentation/features/dashboard/view/staff_dashboard.dart`
- `lib/presentation/features/dashboard/view/parent_dashboard.dart`
- `lib/presentation/features/dashboard/view/admin_dashboard.dart`

---

## Testing Checklist

### On Android Device

#### Test 1: Foreground Entry
- [ ] Open app while outside geofence
- [ ] Walk into geofence radius
- [ ] Sign In button becomes enabled within 5 seconds
- [ ] Notification appears: "Attendance Available"
- [ ] Tap notification → app shows Sign In sheet

#### Test 2: Foreground Exit
- [ ] Walk out of geofence radius
- [ ] Sign In button disables within 5 seconds
- [ ] Notification appears: "Outside School Premises"

#### Test 3: Background Entry
- [ ] Open app while outside geofence
- [ ] Background app (don't kill)
- [ ] Walk into geofence radius
- [ ] Notification appears
- [ ] Open app → Sign In button enabled

#### Test 4: Killed App Entry
- [ ] Open app while outside geofence
- [ ] Force kill app
- [ ] Walk into geofence radius
- [ ] Notification appears in notification center
- [ ] Open app from notification
- [ ] Sign In button shows enabled

#### Test 5: App Restart Inside Geofence
- [ ] Enter geofence with app open
- [ ] Sign In button enabled
- [ ] Force kill app
- [ ] Reopen app
- [ ] Sign In button immediately shows enabled (no delay)

#### Test 6: Dashboard Card Updates
- [ ] Verify all three dashboard card types update correctly:
  - [ ] Staff dashboard (my_day_card.dart)
  - [ ] Parent dashboard (my_childs_day_card.dart)
  - [ ] Admin dashboard (my_day_card.dart)

### Android Manifest Verification
- [x] `ACCESS_FINE_LOCATION` permission
- [x] `ACCESS_COARSE_LOCATION` permission
- [x] `ACCESS_BACKGROUND_LOCATION` permission
- [x] `FOREGROUND_SERVICE_LOCATION` permission
- [x] `POST_NOTIFICATIONS` permission
- [x] `RECEIVE_BOOT_COMPLETED` permission
- [x] `GeofenceBroadcastReceiver` registered with implicit intent filter
- [x] `GeofenceBootReceiver` registered for BOOT_COMPLETED and MY_PACKAGE_REPLACED

---

## Performance Considerations

1. **Notification Deduplication**: `_triggerNotificationIfNeeded()` tracks `_lastNotifiedStatus` to prevent duplicate notifications
2. **Event Stream**: Only the active listener receives events; no redundant processing
3. **State Persistence**: SharedPreferences used for instant app restart state restoration
4. **Background Task**: Minimal overhead; only state updates and notification shown

---

## Known Limitations & Future Improvements

1. **iOS Implementation**: Should be tested separately; uses `CLLocationManager` significant location changes
2. **Battery Drain**: Geofence monitoring has minimal battery impact but could be optimized with:
   - Adaptive radius based on user behavior
   - Disable geofence during school hours
3. **Network Dependency**: Initial school location fetch requires network; works offline after first load

---

## Rollback Instructions

If issues arise, revert these commits and check:
1. Android location permissions actually granted
2. Device has location services enabled
3. School coordinates correctly configured in backend
4. Geofence radius reasonable (250m default)
5. Device time/timezone correct

---

**Status**: Ready for QA testing on Android devices
**Last Updated**: 2026-06-01
