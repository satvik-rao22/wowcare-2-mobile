import 'package:wowcare/core/util/logger_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:wowcare/core/background/geofence_background_task.dart';
import '../../../../domain/features/geofencing/entities/geofence_config.dart';
import '../../../../domain/features/geofencing/entities/geofence_status.dart';
import '../../../../domain/features/geofencing/entities/location_permission_level.dart';
import '../../../../domain/features/geofencing/usecases/check_location_permission_usecase.dart';
import '../../../../domain/features/geofencing/usecases/get_school_location_usecase.dart';
import '../../../../domain/features/geofencing/usecases/request_location_permission_usecase.dart';
import '../../../../domain/features/geofencing/usecases/watch_geofence_usecase.dart';
import '../../../../shared/services/geofence_notification_service.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
part 'geofence_state.dart';

class GeofenceCubit extends Cubit<GeofenceState> with WidgetsBindingObserver {
  static const _nativeGeofenceChannel = MethodChannel(
    'com.wowcare.geofencing/native',
  );
  static const _nativeGeofenceEvents = EventChannel(
    'com.wowcare.geofencing/events',
  );

  // SharedPreferences keys — shared with native implementations.
  static const _prefsSchoolLatKey = 'geofence_school_lat';
  static const _prefsSchoolLonKey = 'geofence_school_lon';
  static const _prefsSchoolRadiusKey = 'geofence_school_radius_m';
  static const _prefsGpsSignInEnabledKey = 'geofence_gps_sign_in_enabled';
  static const _prefsLastGeofenceStatusKey = 'geofence_last_status';
  // Hysteresis: exit threshold = radius + 50 m to prevent boundary flickering.
  static const double _hysteresisExitExtraMeters = 50.0;

  GeofenceCubit({
    required CheckLocationPermissionUseCase checkLocationPermissionUseCase,
    required RequestLocationPermissionUseCase requestLocationPermissionUseCase,
    required GetSchoolLocationUseCase getSchoolLocationUseCase,
    required WatchGeofenceUseCase watchGeofenceUseCase,
    required GeofenceNotificationService notificationService,
  }) : _checkPerm = checkLocationPermissionUseCase,
       _requestPerm = requestLocationPermissionUseCase,
       _getSchoolLocation = getSchoolLocationUseCase,
       _watchGeofence = watchGeofenceUseCase,
       _notifications = notificationService,
       super(const GeofenceState.initial()) {
    _nativeGeofenceChannel.setMethodCallHandler(_handleNativeCallbacks);
    WidgetsBinding.instance.addObserver(this);
  }

  final CheckLocationPermissionUseCase _checkPerm;
  final RequestLocationPermissionUseCase _requestPerm;
  final GetSchoolLocationUseCase _getSchoolLocation;
  final WatchGeofenceUseCase _watchGeofence;
  final GeofenceNotificationService _notifications;

  StreamSubscription<GeofenceStatus>? _subscription;
  StreamSubscription<dynamic>? _nativeSubscription;
  GeofenceConfig? _config;
  int _signInCheckGeneration = 0;

  // ── iOS native callbacks ───────────────────────────────────────────────────

  Future<void> _handleNativeCallbacks(MethodCall call) async {
    if (!Platform.isIOS) return;
    if (call.method != 'geofenceStatusChanged') return;
    if (_config?.gpsSignInEnabled == false) return;
    final args = call.arguments as Map?;
    final isInside = args?['isInside'] == true;
    final newStatus = isInside ? GeofenceStatus.within : GeofenceStatus.outside;
    final newCubitStatus = isInside
        ? GeofenceCubitStatus.withinRange
        : GeofenceCubitStatus.outsideRange;
    if (state.status != newCubitStatus) {
      emit(state.copyWith(status: newCubitStatus));
    }
  }

  // ── App lifecycle (foreground-only tracking gate) ──────────────────────────
  //
  // Background/terminated tracking is only ever appropriate for `always`.
  // Everything else (denied, permanentlyDenied, whileInUse — including iOS's
  // "Allow Once") must stop tracking the instant the app leaves the
  // foreground, and only whileInUse resumes it automatically on return (denied/
  // permanentlyDenied have nothing to resume until the user re-grants access).

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    // Deliberately keyed off `.paused` only (not `.inactive`/`.hidden`, which
    // also fire on trivial transient interruptions like Control Center or an
    // incoming call banner) so foreground-only users aren't stop/restarted on
    // every brief interruption — only on an actual background transition.
    if (lifecycleState == AppLifecycleState.paused) {
      if (state.permissionLevel != LocationPermissionLevel.always) {
        AppLogger.d(
          '[GeofenceCubit] App paused (permissionLevel=${state.permissionLevel}) — stopping monitoring',
        );
        stopMonitoring();
      }
      return;
    }
    if (lifecycleState == AppLifecycleState.resumed) {
      // Reconcile first (permission/GPS may have changed in Settings while
      // backgrounded) — it owns deciding whether/how to resume monitoring,
      // including the whileInUse-only lightweight resume, so this is the
      // only call needed here.
      unawaited(_reconcilePermissionState());
    }
  }

  /// Restarts the lightweight listeners only — school config is already
  /// cached from the last successful init, so this does not re-request
  /// permission or re-fetch school location.
  void _resumeForegroundMonitoring() {
    if (_config == null || isClosed) return;
    _startNativeEvents();
    _startStream();
  }

  // ── Permission reconciliation (Phase 4) ─────────────────────────────────────
  //
  // Detects permission/GPS-service changes made outside the app (e.g. via
  // Settings) and brings monitoring back in line with the current OS state.
  // Read-only with respect to permission requests — never triggers a fresh
  // OS prompt, since this runs automatically on every resume, not from an
  // explicit user action.
  Future<void> _reconcilePermissionState() async {
    if (isClosed || state.schoolCode.isEmpty) return;

    final check = await _checkPerm();
    final previousLevel = state.permissionLevel;
    final wasServiceDisabled = state.status == GeofenceCubitStatus.locationDisabled;
    final permissionChanged = check.permissionLevel != previousLevel;

    AppLogger.d(
      '[GeofenceCubit] Reconcile — permission: $previousLevel → ${check.permissionLevel}, '
      'serviceEnabled: ${check.serviceEnabled}, changed=$permissionChanged',
    );

    // ── Location services turned off ──
    if (!check.serviceEnabled) {
      if (!wasServiceDisabled) stopMonitoring();
      emit(
        state.copyWith(
          status: GeofenceCubitStatus.locationDisabled,
          permissionLevel: check.permissionLevel,
        ),
      );
      unawaited(_syncBackgroundHealthCheck());
      return;
    }

    // ── Downgraded to denied/permanentlyDenied — settle without re-prompting.
    // The user must use the existing "tap to enable" retry flow to re-request. ──
    if (!_hasUsablePermission(check.permissionLevel)) {
      if (permissionChanged) stopMonitoring();
      emit(
        state.copyWith(
          status: GeofenceCubitStatus.permissionDenied,
          permissionLevel: check.permissionLevel,
        ),
      );
      unawaited(_syncBackgroundHealthCheck());
      return;
    }

    // ── Services just came back on, or permission moved between whileInUse
    // and always — both already-granted levels, so re-running the full init
    // is safe: it will not hit the request-permission branch. ──
    if (wasServiceDisabled || permissionChanged) {
      AppLogger.d(
        '[GeofenceCubit] Reconcile — re-initializing (servicesResumed=$wasServiceDisabled, permissionChanged=$permissionChanged)',
      );
      stopMonitoring();
      await _checkAndStartMonitoring(schoolCode: state.schoolCode, isRefresh: true);
      return;
    }

    // ── Nothing changed — just resume the lightweight listeners Phase 3.1
    // stopped on pause (only relevant for whileInUse; `always` was never
    // stopped, denied/permanentlyDenied have nothing to resume). ──
    if (check.permissionLevel == LocationPermissionLevel.whileInUse) {
      _resumeForegroundMonitoring();
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> initForSchool({required String schoolCode}) async {
    debugPrint('╔══════════════════════════════════════════════════╗');
    debugPrint('║  GEOFENCE initForSchool CALLED                   ║');
    debugPrint('╠══════════════════════════════════════════════════╣');
    debugPrint('║  schoolCode : "$schoolCode"');
    debugPrint('║  currentStatus : ${state.status}');
    debugPrint('║  currentSchoolCode : "${state.schoolCode}"');
    debugPrint('╚══════════════════════════════════════════════════╝');
    AppLogger.d('[GeofenceCubit] initForSchool: $schoolCode');

    if (schoolCode.isEmpty) {
      debugPrint('[GeofenceCubit] ⚠️ EARLY EXIT — schoolCode is empty! Check StorageKeys.schoolCode in storage.');
      return;
    }

    // Always ensure the staff sign-in status is refreshed on initialization
    await checkStaffSignInStatus();

    // Already monitoring this school — keep current state, skip full re-init.
    // NOTE: checkingPermission is intentionally excluded: it is the very first
    // intermediate state before monitoring has actually started, so a second
    // initForSchool() call while still in that state must NOT be skipped.
    if (state.schoolCode == schoolCode &&
        (state.status == GeofenceCubitStatus.withinRange ||
            state.status == GeofenceCubitStatus.outsideRange ||
            state.status == GeofenceCubitStatus.gpsDisabledByAdmin ||
            state.status == GeofenceCubitStatus.checking ||
            state.status == GeofenceCubitStatus.fetchingSchoolLocation)) {
      debugPrint('[GeofenceCubit] ⚠️ EARLY EXIT — already monitoring "$schoolCode" in state ${state.status} — skipping re-init');
      AppLogger.d('[GeofenceCubit] Already monitoring, skipping re-init');
      return;
    }

    stopMonitoring();

    // ── Instantly restore last-known state from SharedPreferences ──────────
    // This makes the button visually correct the moment the dashboard opens,
    // without waiting for permission checks or API calls to complete.
    final lastStatus = await _restoreLastKnownStatus();
    if (lastStatus != null) {
      final prefs = await SharedPreferences.getInstance();
      emit(
        GeofenceState(
          status: lastStatus,
          schoolCode: schoolCode,
          gpsSignInEnabled: prefs.getBool(_prefsGpsSignInEnabledKey) ?? true,
          radiusMeters: prefs.getDouble(_prefsSchoolRadiusKey),
          // Preserve the already-known permission level (freshly set by the
          // checkStaffSignInStatus()/prior init above) instead of silently
          // resetting it to the class default (denied) — an unguarded reset
          // here fed a stale value into the next resume's reconciliation
          // comparison, spuriously triggering an unnecessary re-init.
          permissionLevel: state.permissionLevel,
          isStaffSignedIn: state.isStaffSignedIn,
          allChildrenSignedIn: state.allChildrenSignedIn,
        ),
      );
    } else {
      emit(
        GeofenceState(
          status: GeofenceCubitStatus.checkingPermission,
          schoolCode: schoolCode,
          permissionLevel: state.permissionLevel,
          isStaffSignedIn: state.isStaffSignedIn,
          allChildrenSignedIn: state.allChildrenSignedIn,
        ),
      );
    }
    // ── Then do the full async init (permission + API + stream) ────────────
    // isRefresh: true so app restart — like a dashboard refresh — is one of
    // the two points where the "you can now Sign In or Sign Out" notification
    // is (re-)evaluated against current sign-in status, per requirement.
    await _checkAndStartMonitoring(schoolCode: schoolCode, isRefresh: true);
  }

  /// Call after the user taps "retry" on a permission-denied screen.
  Future<void> retryPermission() async {
    final schoolCode = state.schoolCode;
    if (schoolCode.isEmpty) return;
    await _requestAllPermissions();
    await _checkAndStartMonitoring(schoolCode: schoolCode);
  }

  /// Force-refresh attendance settings and restart the geofence stream.
  /// Useful when the admin may have changed the GPS toggle or radius.
  Future<void> refreshSettings() async {
    final schoolCode = state.schoolCode;
    if (schoolCode.isEmpty) return;
    AppLogger.d('[GeofenceCubit] refreshSettings called');
    stopMonitoring();
    emit(state.copyWith(
      status: GeofenceCubitStatus.fetchingSchoolLocation,
      refreshNonce: state.refreshNonce + 1,
    ));
    await _checkAndStartMonitoring(schoolCode: schoolCode, isRefresh: true);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Equivalent to the previous boolean `hasPermission` check: any granted
  /// level (foreground or background) counts as usable; denied/permanently
  /// denied do not.
  bool _hasUsablePermission(LocationPermissionLevel level) =>
      level == LocationPermissionLevel.whileInUse ||
      level == LocationPermissionLevel.always;

  Future<void> _requestAllPermissions() async {
    await _requestPerm();
    // Request notification permission so background geofence notifications
    // actually appear. Android 13+ requires POST_NOTIFICATIONS at runtime;
    // iOS needs the UNUserNotificationCenter prompt.
    try {
      await Permission.notification.request();
    } catch (_) {}
    // Ensure the flutter_local_notifications plugin is initialised and the iOS
    // system prompt has been shown BEFORE the first geofence event fires.
    await _notifications.init();
  }

  /// Ensures the local-notification plugin is initialised regardless of whether
  /// the user was already permissioned (so `_requestAllPermissions` was skipped).
  Future<void> _ensureNotificationsInitialised() async {
    try {
      await _notifications.init();
    } catch (_) {}
  }

  // Reentrancy guard for _doCheckAndStartMonitoring. That method mutates
  // shared fields (_config, _subscription, _nativeSubscription) across
  // multiple await points (permission check, school-location API, GPS
  // fetch). initForSchool/retryPermission/refreshSettings and the
  // resume-triggered _reconcilePermissionState can all call it, and since
  // app-resume is an automatic trigger (not user-serialized like the others),
  // two invocations can genuinely overlap — e.g. a resume firing while a
  // cold-start init is still awaiting a network call. An overlapping call
  // would cancel/overwrite the first call's in-flight subscriptions and
  // config, leaving the cubit stuck on a stale or incorrect status.
  //
  // Strategy: AWAIT, not ignore or queue-a-second-run. A second caller waits
  // for the in-flight call to finish, then returns — it does not start its
  // own redundant run. This guarantees at most one execution at a time,
  // never silently drops a caller's request (unlike "ignore"), and never
  // needs a second full network+GPS round trip (unlike "queue").
  Completer<void>? _monitoringLock;

  Future<void> _checkAndStartMonitoring({
    required String schoolCode,
    bool isRefresh = false,
  }) async {
    if (_monitoringLock != null) {
      AppLogger.d(
        '[GeofenceCubit] _checkAndStartMonitoring already in progress — awaiting existing call instead of running concurrently',
      );
      await _monitoringLock!.future;
      return;
    }
    final completer = Completer<void>();
    _monitoringLock = completer;
    try {
      await _doCheckAndStartMonitoring(
        schoolCode: schoolCode,
        isRefresh: isRefresh,
      );
    } finally {
      _monitoringLock = null;
      completer.complete();
    }
  }

  Future<void> _doCheckAndStartMonitoring({
    required String schoolCode,
    bool isRefresh = false,
  }) async {
    try {
      debugPrint('[GeofenceCubit] ▶ _checkAndStartMonitoring start — schoolCode="$schoolCode"');

      final permCheck = await _checkPerm();
      debugPrint('[GeofenceCubit] permCheck → serviceEnabled=${permCheck.serviceEnabled} permissionLevel=${permCheck.permissionLevel}');

      if (!permCheck.serviceEnabled) {
        debugPrint('[GeofenceCubit] ⚠️ EARLY EXIT — location service is DISABLED on device. User must enable in Settings > Privacy > Location Services.');
        emit(
          state.copyWith(
            status: GeofenceCubitStatus.locationDisabled,
            permissionLevel: permCheck.permissionLevel,
          ),
        );
        return;
      }
      var permissionLevel = permCheck.permissionLevel;
      if (!_hasUsablePermission(permissionLevel)) {
        debugPrint('[GeofenceCubit] No location permission — requesting now...');
        await _requestAllPermissions();
        final recheck = await _checkPerm();
        permissionLevel = recheck.permissionLevel;
        debugPrint('[GeofenceCubit] recheck after request → serviceEnabled=${recheck.serviceEnabled} permissionLevel=${recheck.permissionLevel}');
        if (!_hasUsablePermission(permissionLevel)) {
          debugPrint('[GeofenceCubit] ⚠️ EARLY EXIT — location permission DENIED after request. User tapped "Don\'t Allow".');
          emit(
            state.copyWith(
              status: GeofenceCubitStatus.permissionDenied,
              permissionLevel: permissionLevel,
            ),
          );
          return;
        }
        debugPrint('[GeofenceCubit] ✅ Permission granted after request');
      } else {
        debugPrint('[GeofenceCubit] ✅ Permission already granted — skipping request');
        // Permission already granted — _requestAllPermissions was skipped, so
        // the notification plugin may not have been initialised yet.
        unawaited(_ensureNotificationsInitialised());
      }

      emit(
        state.copyWith(
          status: GeofenceCubitStatus.fetchingSchoolLocation,
          permissionLevel: permissionLevel,
        ),
      );

      // ── Kick off GPS fetch NOW, in parallel with the school-location API ──
      // This way both complete at the same time instead of one after the other.
      final positionFuture = _fetchPositionQuickly();

      debugPrint('[GeofenceCubit] ▶ calling getSchoolLocation API for "$schoolCode"...');
      // Fetches school lat/lon AND attendance-settings (radius + gpsSignInEnabled)
      // in a single call — the repository fans out both API calls in parallel.
      _config = await _getSchoolLocation(schoolCode: schoolCode);
      debugPrint('[GeofenceCubit] ✅ getSchoolLocation API returned successfully');

      // ── DEBUG: print geofence values to terminal ──────────────────────────
      debugPrint('╔══════════════════════════════════════════════════╗');
      debugPrint('║  GEOFENCE CONFIG LOADED                          ║');
      debugPrint('╠══════════════════════════════════════════════════╣');
      debugPrint('║  schoolCode  : ${_config?.schoolCode}');
      debugPrint('║  latitude    : ${_config?.latitude}');
      debugPrint('║  longitude   : ${_config?.longitude}');
      debugPrint('║  radius (m)  : ${_config?.radiusMeters}');
      debugPrint('║  gpsEnabled  : ${_config?.gpsSignInEnabled}');
      debugPrint(
        '║  autoSignOut : ${_config?.autoSignOutEnabled}  (delay: ${_config?.autoSignOutDelayMinutes} min)',
      );
      debugPrint('╚══════════════════════════════════════════════════╝');
      // ── end debug ─────────────────────────────────────────────────────────
      AppLogger.d(
        '[GeofenceCubit] Config loaded — lat=${_config?.latitude} '
        'lon=${_config?.longitude} radius=${_config?.radiusMeters}m '
        'gpsEnabled=${_config?.gpsSignInEnabled}',
      );

      await _persistConfig(_config!);
      await _updateNativeGeofence(_config!);

      // If admin turned off GPS sign-in, stop here and surface that state.
      if (!_config!.gpsSignInEnabled) {
        AppLogger.d('[GeofenceCubit] GPS sign-in disabled by admin');
        emit(
          state.copyWith(
            status: GeofenceCubitStatus.gpsDisabledByAdmin,
            gpsSignInEnabled: false,
            parentGpsSignInEnabled: _config!.parentGpsSignInEnabled,
            radiusMeters: _config!.radiusMeters,
            permissionLevel: permissionLevel,
          ),
        );
        unawaited(_syncBackgroundHealthCheck());
        return;
      }

      // ── Resolve state from the parallel GPS fetch (likely already done) ──
      final position = await positionFuture;
      GeofenceCubitStatus immediateStatus;
      GeofenceStatus? immediateGeofenceStatus;

      if (position != null) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _config!.latitude,
          _config!.longitude,
        );
        // Inside: trust the GPS-reported distance directly.
        // Using (distance + accuracy <= radius) was too pessimistic — a user
        // at 180 m with 100 m medium-accuracy never resolved to withinRange.
        //
        // Outside: apply hysteresis so a noisy fix near the boundary doesn't
        // incorrectly flip the user to outsideRange.
        final accuracy = position.accuracy.clamp(0.0, double.infinity);
        final isInside = distance <= _config!.radiusMeters;
        final confidentlyOutside =
            distance - accuracy > _config!.radiusMeters + _hysteresisExitExtraMeters;

        if (isInside) {
          immediateStatus = GeofenceCubitStatus.withinRange;
          immediateGeofenceStatus = GeofenceStatus.within;
        } else if (confidentlyOutside) {
          immediateStatus = GeofenceCubitStatus.outsideRange;
          immediateGeofenceStatus = GeofenceStatus.outside;
        } else {
          // Near boundary: GPS accuracy is too large to be sure either way.
          // Try the last-persisted status; if there is none (first launch),
          // leave the state as 'checking' and schedule a high-accuracy
          // re-check so the user isn't locked out on their first visit.
          final restored = await _restoreLastKnownStatus();
          if (restored != null) {
            immediateStatus = restored;
          } else {
            immediateStatus = GeofenceCubitStatus.checking;
            unawaited(_refineWithHighAccuracyFix());
          }
        }

        // ── Comprehensive GPS diagnostic log ──────────────────────────────
        debugPrint('╔══════════════════════════════════════════════════════╗');
        debugPrint('║  GPS POSITION CHECK                                  ║');
        debugPrint('╠══════════════════════════════════════════════════════╣');
        debugPrint('║  Device lat      : ${position.latitude}');
        debugPrint('║  Device lon      : ${position.longitude}');
        debugPrint('║  School lat      : ${_config!.latitude}');
        debugPrint('║  School lon      : ${_config!.longitude}');
        debugPrint('║  Distance        : ${distance.toStringAsFixed(1)} m');
        debugPrint('║  Allowed radius  : ${_config!.radiusMeters} m');
        debugPrint('║  GPS accuracy    : ±${accuracy.toStringAsFixed(1)} m');
        debugPrint('║  Is inside       : $isInside');
        debugPrint('║  Confidently out : $confidentlyOutside');
        debugPrint('║  → Status        : $immediateStatus');
        debugPrint('╚══════════════════════════════════════════════════════╝');

        AppLogger.d(
          '[GeofenceCubit] GPS check — '
          'deviceLat=${position.latitude} deviceLon=${position.longitude} '
          'schoolLat=${_config!.latitude} schoolLon=${_config!.longitude} '
          'distance=${distance.toStringAsFixed(1)}m '
          'accuracy=±${accuracy.toStringAsFixed(1)}m '
          'radius=${_config!.radiusMeters}m '
          'isInside=$isInside confidentlyOutside=$confidentlyOutside '
          'status=$immediateStatus',
        );
      } else {
        // GPS unavailable — fall back to last-known persisted status.
        final restored = await _restoreLastKnownStatus();
        immediateStatus = restored ?? GeofenceCubitStatus.checking;
        debugPrint('[GeofenceCubit] ⚠️ GPS position unavailable — using '
            'persisted status: $immediateStatus');
        AppLogger.d('[GeofenceCubit] GPS unavailable — restored=$restored → $immediateStatus');
      }

      emit(
        state.copyWith(
          status: immediateStatus,
          gpsSignInEnabled: true,
          parentGpsSignInEnabled: _config!.parentGpsSignInEnabled,
          radiusMeters: _config!.radiusMeters,
          permissionLevel: permissionLevel,
        ),
      );
      unawaited(_syncBackgroundHealthCheck());

      _startNativeEvents();
      _startStream();

      // ── Android: sync authoritative inside/outside from native on cold start ──
      // GeofencingClient fires events only on boundary crosses, so after a cold
      // start Flutter would rely solely on the GPS check above. The native side
      // persists the last known state reliably (written by GeofenceBroadcastReceiver
      // even when the app is killed), so we query it to get ground truth.
      //
      // We sync twice:
      //   • Immediately — picks up state from any prior boundary cross.
      //   • After 4 s   — picks up the INITIAL_TRIGGER_ENTER/EXIT event that
      //     GeofencingClient fires asynchronously after registration. Without
      //     this delay the first sync always reads the default (isInside=false)
      //     before the broadcast receiver has processed the initial trigger.
      if (Platform.isAndroid) {
        unawaited(_syncFromNativeGeofenceStatus());
        unawaited(
          Future.delayed(const Duration(seconds: 4), () {
            if (!isClosed) unawaited(_syncFromNativeGeofenceStatus());
          }),
        );
      }

      // ── iOS: sync authoritative inside/outside from native on cold start ──
      //
      // We sync TWICE, mirroring the Android pattern:
      //
      //   • Immediately (positiveOnly=true): Only trust isInside=true from
      //     UserDefaults. A stale isInside=false default must NOT downgrade
      //     a GPS-pending 'checking' state — the user might be physically
      //     inside the zone but UserDefaults hasn't been updated yet because
      //     didDetermineState hasn't fired.
      //
      //   • After 5 s: CLLocationManager.requestState fires
      //     didDetermineState asynchronously (typically 1–5 s after
      //     startMonitoring + requestState). The 5-second delay ensures
      //     UserDefaults has been written by the time we read it, giving us
      //     an authoritative inside/outside reading. Without this delay the
      //     first sync always reads the stale default (isInside=false) and
      //     the sign-in button stays disabled even when the user is physically
      //     inside the school zone.
      if (Platform.isIOS) {
        unawaited(_syncFromNativeGeofenceStatusIOS(positiveOnly: true));
        unawaited(
          Future.delayed(const Duration(seconds: 5), () {
            if (!isClosed) unawaited(_syncFromNativeGeofenceStatusIOS());
          }),
        );
      }
    } catch (e, st) {
      debugPrint('╔══════════════════════════════════════════════════╗');
      debugPrint('║  GEOFENCE INIT ERROR                             ║');
      debugPrint('╠══════════════════════════════════════════════════╣');
      debugPrint('║  $e');
      debugPrint('║  $st');
      debugPrint('╚══════════════════════════════════════════════════╝');
      AppLogger.d('[GeofenceCubit] Init error: $e');
      emit(
        state.copyWith(
          status: GeofenceCubitStatus.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  void _startStream() {
    if (Platform.isAndroid)
      return; // Android uses OS-level GeofencingClient events.
    if (_config == null) return;
    final config = _config!;

    AppLogger.d(
      '[GeofenceCubit] Starting stream — radius=${config.radiusMeters}m '
      'hysteresisExit=${config.radiusMeters + _hysteresisExitExtraMeters}m',
    );

    // WatchGeofenceUseCase emits GeofenceStatus (within/outside) but we also
    // need raw distance to display in the UI, so we tap into the position
    // stream separately via a custom listener on the same WatchGeofenceUseCase
    // observable (which already filters mocked/stale positions).
    _subscription = _watchGeofence(config: config).distinct().listen(
      (geofenceStatus) {
        final newCubitStatus = geofenceStatus == GeofenceStatus.within
            ? GeofenceCubitStatus.withinRange
            : GeofenceCubitStatus.outsideRange;

        if (state.status != newCubitStatus) {
          emit(state.copyWith(status: newCubitStatus));
        }
      },
      onError: (Object e) {
        // A stream error (e.g. location service killed) is transient.
        // Keep the last visible UI state and auto-restart after a short delay
        // so the button is never permanently disabled by a recoverable error.
        AppLogger.d('[GeofenceCubit] Stream error (will retry): $e');
        unawaited(_subscription?.cancel());
        _subscription = null;

        if (isClosed) return;
        // Hold whatever status was showing, then restart in 5 s.
        unawaited(
          Future.delayed(const Duration(seconds: 5), () {
            if (!isClosed && _config != null) {
              AppLogger.d('[GeofenceCubit] Restarting stream after error');
              _startStream();
            }
          }),
        );
      },
    );
  }

  void _startNativeEvents() {
    if (!Platform.isAndroid) return;
    unawaited(_nativeSubscription?.cancel());
    _nativeSubscription = _nativeGeofenceEvents.receiveBroadcastStream().listen(
      (event) {
        final args = event is Map ? event : null;
        final isInside = args?['isInside'] == true;
        final nextStatus = isInside
            ? GeofenceCubitStatus.withinRange
            : GeofenceCubitStatus.outsideRange;
        if (state.status != nextStatus) {
          emit(state.copyWith(status: nextStatus));
        }
      },
      onError: (Object e) {
        AppLogger.d('[GeofenceCubit] Native event stream error: $e');
      },
    );
  }


  /// Synchronizes the current "nothing to do" flag (sign in status) to the
  /// native layer whenever sign-in status changes (dashboard refresh,
  /// sign-in/sign-out, resume).
  void _reevaluateNotificationForCurrentStatus() {
    unawaited(_syncSignInStatusToNative());
  }

  /// Pushes the current "nothing to do" (everyone already signed in) flag to
  /// the native side, so the notification the OS shows for a real background
  /// boundary-cross — which Dart cannot intercept while backgrounded/killed —
  /// can also be suppressed based on sign-in status instead of firing blind.
  Future<void> _syncSignInStatusToNative() async {
    if (!(Platform.isIOS || Platform.isAndroid)) return;
    try {
      await _nativeGeofenceChannel.invokeMethod('updateSignInStatus', {
        'nothingToDo': state.isStaffSignedIn || state.allChildrenSignedIn,
      });
    } catch (e) {
      AppLogger.d('[GeofenceCubit] Failed to sync sign-in status to native: $e');
    }
  }

  /// Called when the initial medium-accuracy GPS fix lands near the geofence
  /// boundary and there is no prior history to fall back to. Requests a
  /// high-accuracy fix (up to 15 s) and re-evaluates inside/outside so the
  /// user is not permanently stuck on 'checking' on their first visit.
  Future<void> _refineWithHighAccuracyFix() async {
    if (_config == null || isClosed) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (_config == null || isClosed) return;
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _config!.latitude,
        _config!.longitude,
      );
      final isInside = distance <= _config!.radiusMeters;
      final newStatus = isInside
          ? GeofenceCubitStatus.withinRange
          : GeofenceCubitStatus.outsideRange;
      AppLogger.d(
        '[GeofenceCubit] High-accuracy refinement — '
        'distance=${distance.toStringAsFixed(1)}m '
        'radius=${_config!.radiusMeters}m '
        'status=$newStatus',
      );
      if (state.status == GeofenceCubitStatus.checking) {
        emit(state.copyWith(status: newStatus));
      }
    } catch (e) {
      // High-accuracy fix failed (timeout or hardware error).
      // Do NOT emit outsideRange — that would lock the button even when the
      // user is physically inside the zone. Leave the state as 'checking' so
      // the Dart position stream and the native CLRegion callback can still
      // resolve it when the next GPS fix arrives.
      AppLogger.d('[GeofenceCubit] High-accuracy refinement failed: $e — keeping checking state');
    }
  }

  /// Fetches device position quickly using medium accuracy so it resolves
  /// from Wi-Fi/cell towers in under a second on most devices.
  /// Falls back to the last known position if the timed request fails.
  Future<Position?> _fetchPositionQuickly() async {
    // iOS GPS cold start needs up to 15 s to get a first fix; 8 s caused
    // frequent timeouts that left state as 'checking' and then got incorrectly
    // resolved to 'outsideRange' by the native-sync guard.
    // Android WiFi/cell-tower fixes resolve in 1-3 s so 12 s is still fast.
    // LocationAccuracy.high → kCLLocationAccuracyNearestTenMeters on iOS (≈10 m).
    final timeout = Platform.isIOS
        ? const Duration(seconds: 15)
        : const Duration(seconds: 8);

    AppLogger.d('[GeofenceCubit] Fetching GPS position (timeout=${timeout.inSeconds}s, platform=${Platform.operatingSystem})');

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      AppLogger.d(
        '[GeofenceCubit] GPS fix obtained — '
        'lat=${pos.latitude} lon=${pos.longitude} '
        'accuracy=±${pos.accuracy.toStringAsFixed(1)}m '
        'isMocked=${pos.isMocked}',
      );
      debugPrint('[GeofenceCubit] 📍 GPS fix: lat=${pos.latitude} lon=${pos.longitude} accuracy=±${pos.accuracy.toStringAsFixed(1)}m');
      return pos;
    } catch (e) {
      AppLogger.d('[GeofenceCubit] getCurrentPosition failed ($e) — trying getLastKnownPosition');
      debugPrint('[GeofenceCubit] ⚠️ getCurrentPosition timed out or failed: $e');
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          AppLogger.d(
            '[GeofenceCubit] Using last known position — '
            'lat=${last.latitude} lon=${last.longitude} '
            'accuracy=±${last.accuracy.toStringAsFixed(1)}m '
            'age=${DateTime.now().toUtc().difference(last.timestamp).inSeconds}s',
          );
          debugPrint('[GeofenceCubit] 📍 Last known position: lat=${last.latitude} lon=${last.longitude} accuracy=±${last.accuracy.toStringAsFixed(1)}m age=${DateTime.now().toUtc().difference(last.timestamp).inSeconds}s');
        } else {
          debugPrint('[GeofenceCubit] ⚠️ No last known position available');
        }
        return last;
      } catch (_) {
        debugPrint('[GeofenceCubit] ⚠️ getLastKnownPosition also failed');
        return null;
      }
    }
  }

  /// Queries the native Android GeofencingClient's last-persisted inside/outside
  /// state and syncs it to the cubit. Called once after cold start because the
  /// EventChannel only fires on boundary crosses, not on app resume.
  ///
  /// Important: the native `geofence_last_notified_inside` SharedPreference
  /// defaults to **false** until the very first OS ENTER event fires (fresh
  /// install, no boundary cross yet). We must therefore never let a native
  /// `false` override a GPS-determined `withinRange` — doing so would disable
  /// the sign-in button even when the user is physically inside the zone.
  ///
  /// Rule:
  ///   • native=true  → always trust (positive evidence of being inside)
  ///   • native=false → only use when the current state is NOT withinRange
  ///                    (avoids overriding a valid GPS-inside determination
  ///                     with a stale/default native outside value)
  Future<void> _syncFromNativeGeofenceStatus() async {
    try {
      final raw = await _nativeGeofenceChannel.invokeMethod<dynamic>(
        'getGeofenceStatus',
      );
      final map = raw is Map ? raw : null;
      if (map == null || isClosed) return;
      final isInside = map['isInside'] == true;

      // Don't downgrade GPS-confirmed withinRange with a native default=false.
      if (!isInside && state.status == GeofenceCubitStatus.withinRange) {
        AppLogger.d(
          '[GeofenceCubit] Native sync skipped — GPS already confirmed withinRange, native=false is default',
        );
        return;
      }

      final syncedStatus = isInside
          ? GeofenceCubitStatus.withinRange
          : GeofenceCubitStatus.outsideRange;
      AppLogger.d(
        '[GeofenceCubit] Native sync — isInside=$isInside → $syncedStatus',
      );
      if (state.status != syncedStatus) {
        emit(state.copyWith(status: syncedStatus));
      }
    } catch (e) {
      AppLogger.d('[GeofenceCubit] Native status sync failed: $e');
    }
  }

  /// Reads the native iOS `geofence_last_notified_inside` UserDefaults value
  /// and syncs it to the cubit state.
  ///
  /// [positiveOnly]: when true, only apply the sync result if native reports
  /// `isInside=true`. A stale `false` default (fresh install, or user was
  /// outside last session) must not downgrade a GPS-pending 'checking' state
  /// to 'outsideRange' before CLLocationManager.didDetermineState has fired.
  /// Use positiveOnly=true for the immediate call and false for the 5-second
  /// delayed call (by which time didDetermineState has already updated
  /// UserDefaults with the real value).
  Future<void> _syncFromNativeGeofenceStatusIOS({
    bool positiveOnly = false,
  }) async {
    try {
      final raw = await _nativeGeofenceChannel.invokeMethod<dynamic>(
        'getGeofenceStatus',
      );
      final map = raw is Map ? raw : null;
      if (map == null || isClosed) return;
      final isInside = map['isInside'] == true;

      AppLogger.d(
        '[GeofenceCubit] iOS native sync — isInside=$isInside '
        'positiveOnly=$positiveOnly currentStatus=${state.status}',
      );

      // Immediate (positiveOnly) call: ignore stale false to avoid incorrectly
      // resolving a GPS-pending 'checking' state to 'outsideRange'.
      if (positiveOnly && !isInside) {
        AppLogger.d(
          '[GeofenceCubit] iOS immediate sync skipped — '
          'native=false may be stale default (didDetermineState not yet fired)',
        );
        return;
      }

      // Never downgrade a GPS-confirmed withinRange with a native false.
      if (!isInside && state.status == GeofenceCubitStatus.withinRange) {
        AppLogger.d(
          '[GeofenceCubit] iOS native sync skipped — GPS already confirmed withinRange',
        );
        return;
      }

      final syncedStatus = isInside
          ? GeofenceCubitStatus.withinRange
          : GeofenceCubitStatus.outsideRange;
      AppLogger.d(
        '[GeofenceCubit] iOS native sync applying — $syncedStatus',
      );
      if (state.status != syncedStatus) {
        emit(state.copyWith(status: syncedStatus));
      }
    } catch (e) {
      AppLogger.d('[GeofenceCubit] iOS native status sync failed: $e');
    }
  }

  void stopMonitoring() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_nativeSubscription?.cancel());
    _nativeSubscription = null;
    // Deliberately NOT resetting _lastNotifiedStatus here — it tracks the
    // last geofence status the user was actually notified about for the
    // whole session, independent of listener lifecycle. stopMonitoring() is
    // called on every dashboard refresh/reinit (initForSchool, refreshSettings,
    // pause/resume reconciliation); resetting the dedup flag here caused the
    // "Sign In/Out — you can now Sign In or Sign Out" notification to re-fire
    // on every refresh even when the user's status hadn't actually changed.
  }

  // ── WorkManager health check (Phase 5) ──────────────────────────────────────
  //
  // NOT the primary tracking mechanism — real-time geofencing, GPS polling and
  // attendance decisions stay entirely native (region monitoring/GeofencingClient)
  // and in this cubit's own listeners. WorkManager only runs a periodic
  // best-effort recovery task (re-registers native monitoring if the OS
  // silently dropped it) while the app is terminated, and only when the user
  // has actually granted background access and the school has GPS sign-in on.
  Future<void> _syncBackgroundHealthCheck() async {
    final shouldRun =
        state.permissionLevel == LocationPermissionLevel.always &&
        state.gpsSignInEnabled;
    try {
      if (shouldRun) {
        await Workmanager().registerPeriodicTask(
          geofenceHealthCheckTaskUniqueName,
          geofenceHealthCheckTaskName,
          frequency: const Duration(minutes: 15),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
        AppLogger.d('[GeofenceCubit] WorkManager health check registered');
      } else {
        await Workmanager().cancelByUniqueName(geofenceHealthCheckTaskUniqueName);
        AppLogger.d('[GeofenceCubit] WorkManager health check cancelled');
      }
    } catch (e) {
      // Best-effort — WorkManager is a recovery aid, never allow it to affect
      // the primary foreground/native monitoring flow.
      AppLogger.d('[GeofenceCubit] WorkManager sync failed (non-fatal): $e');
    }
  }

  Future<void> _updateNativeGeofence(GeofenceConfig config) async {
    if (!(Platform.isIOS || Platform.isAndroid)) return;
    try {
      await _nativeGeofenceChannel.invokeMethod('updateSchoolLocation', {
        'latitude': config.latitude,
        'longitude': config.longitude,
        'schoolCode': config.schoolCode,
        'radiusMeters': config.radiusMeters,
        'gpsSignInEnabled': config.gpsSignInEnabled,
      });
    } catch (e) {
      AppLogger.d('[GeofenceCubit] Native geofence update error: $e');
    }
  }

  /// Persists config to SharedPreferences so the WorkManager background task
  /// can read it without needing a DI container.
  Future<void> _persistConfig(GeofenceConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsSchoolLatKey, config.latitude);
      await prefs.setDouble(_prefsSchoolLonKey, config.longitude);
      await prefs.setDouble(_prefsSchoolRadiusKey, config.radiusMeters);
      await prefs.setBool(_prefsGpsSignInEnabledKey, config.gpsSignInEnabled);
      // Hysteresis exit extra is a constant — persist so background task can read it.
      await prefs.setDouble(
        'geofence_exit_hysteresis_extra_m',
        _hysteresisExitExtraMeters,
      );
    } catch (e) {
      AppLogger.d('[GeofenceCubit] Failed to persist config: $e');
    }
  }

  Future<GeofenceCubitStatus?> _restoreLastKnownStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsLastGeofenceStatusKey);
      if (raw == null || raw.isEmpty) return null;
      return switch (raw) {
        'within' => GeofenceCubitStatus.withinRange,
        'outside' => GeofenceCubitStatus.outsideRange,
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  Future<void> handleProfileSwitch() async {
    _signInCheckGeneration++;
    emit(state.copyWith(
      isStaffSignedIn: false,
      allChildrenSignedIn: false,
      isSignInStatusLoading: true,
    ));
  }

  void setSignInStatusLoading(bool isLoading) {
    emit(state.copyWith(isSignInStatusLoading: isLoading));
  }

  Future<void> checkStaffSignInStatus() async {
    final currentGen = ++_signInCheckGeneration;
    emit(state.copyWith(isSignInStatusLoading: true));
    try {
      final storage = serviceLocator<StorageService>();
      String staffCode = await resolveStaffCodeForLoggedInUser();
      if (staffCode.isEmpty) {
        staffCode =
            (await storage.getString(StorageKeys.staffCode))?.trim() ?? '';
      }
      if (staffCode.isEmpty) {
        final activeRole =
            (await storage.getString(StorageKeys.activeSchoolRole))
                ?.trim()
                .toUpperCase() ??
            '';
        if (activeRole == 'ADMIN' || activeRole == 'ORG_ADMIN') {
          staffCode =
              (await storage.getString(StorageKeys.userCode))?.trim() ?? '';
        }
      }
      if (staffCode.isEmpty) {
        if (currentGen == _signInCheckGeneration) {
          emit(
            state.copyWith(
              isStaffSignedIn: false,
              isSignInStatusLoading: false,
            ),
          );
        }
        return;
      }
      final getStaffStatusUseCase =
          serviceLocator<GetStaffTodaySignInStatusUseCase>();
      final status = await getStaffStatusUseCase(staffCode: staffCode);
      if (currentGen != _signInCheckGeneration) return;
      final isSignedIn = status?.toUpperCase() == 'SIGNED_IN';
      emit(
        state.copyWith(
          isStaffSignedIn: isSignedIn,
          isSignInStatusLoading: false,
        ),
      );
      _reevaluateNotificationForCurrentStatus();
    } catch (_) {
      if (currentGen == _signInCheckGeneration) {
        emit(
          state.copyWith(
            isStaffSignedIn: false,
            isSignInStatusLoading: false,
          ),
        );
        _reevaluateNotificationForCurrentStatus();
      }
    }
  }

  Future<void> updateStaffSignInStatus(bool isSignedIn) async {
    emit(state.copyWith(isStaffSignedIn: isSignedIn, isSignInStatusLoading: false));
    _reevaluateNotificationForCurrentStatus();
  }

  /// Guardian/parent equivalent of [updateStaffSignInStatus] — called by
  /// MyChildsDayCard whenever it refreshes children's sign-in status, so the
  /// "you can now Sign In or Sign Out" notification can be suppressed once
  /// nothing is left to act on for this guardian.
  Future<void> updateChildrenSignInStatus(bool allSignedIn) async {
    emit(state.copyWith(allChildrenSignedIn: allSignedIn, isSignInStatusLoading: false));
    _reevaluateNotificationForCurrentStatus();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    stopMonitoring();
    return super.close();
  }
}
