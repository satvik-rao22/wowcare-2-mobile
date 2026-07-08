import 'package:wowcare/core/util/logger_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../domain/features/geofencing/entities/geofence_config.dart';
import '../../../../domain/features/geofencing/entities/geofence_status.dart';
import '../../../../domain/features/geofencing/usecases/check_location_permission_usecase.dart';
import '../../../../domain/features/geofencing/usecases/get_school_location_usecase.dart';
import '../../../../domain/features/geofencing/usecases/request_location_permission_usecase.dart';
import '../../../../domain/features/geofencing/usecases/watch_geofence_usecase.dart';
import '../../../../shared/services/geofence_notification_service.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
part 'geofence_state.dart';

class GeofenceCubit extends Cubit<GeofenceState> {
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
  static const _prefsLastNotifiedInsideKey = 'geofence_last_notified_inside';
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
  }

  final CheckLocationPermissionUseCase _checkPerm;
  final RequestLocationPermissionUseCase _requestPerm;
  final GetSchoolLocationUseCase _getSchoolLocation;
  final WatchGeofenceUseCase _watchGeofence;
  final GeofenceNotificationService _notifications;

  StreamSubscription<GeofenceStatus>? _subscription;
  StreamSubscription<dynamic>? _nativeSubscription;
  GeofenceStatus? _lastNotifiedStatus;
  GeofenceConfig? _config;

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
      _triggerNotificationIfNeeded(newStatus);
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
        ),
      );
    } else {
      emit(
        GeofenceState(
          status: GeofenceCubitStatus.checkingPermission,
          schoolCode: schoolCode,
        ),
      );
    }
    // ── Then do the full async init (permission + API + stream) ────────────
    await _checkAndStartMonitoring(schoolCode: schoolCode);
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
    emit(state.copyWith(status: GeofenceCubitStatus.fetchingSchoolLocation));
    await _checkAndStartMonitoring(schoolCode: schoolCode, isRefresh: true);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

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

  Future<void> _checkAndStartMonitoring({
    required String schoolCode,
    bool isRefresh = false,
  }) async {
    try {
      debugPrint('[GeofenceCubit] ▶ _checkAndStartMonitoring start — schoolCode="$schoolCode"');

      final permCheck = await _checkPerm();
      debugPrint('[GeofenceCubit] permCheck → serviceEnabled=${permCheck.serviceEnabled} hasPermission=${permCheck.hasPermission}');

      if (!permCheck.serviceEnabled) {
        debugPrint('[GeofenceCubit] ⚠️ EARLY EXIT — location service is DISABLED on device. User must enable in Settings > Privacy > Location Services.');
        emit(state.copyWith(status: GeofenceCubitStatus.locationDisabled));
        return;
      }
      if (!permCheck.hasPermission) {
        debugPrint('[GeofenceCubit] No location permission — requesting now...');
        await _requestAllPermissions();
        final recheck = await _checkPerm();
        debugPrint('[GeofenceCubit] recheck after request → serviceEnabled=${recheck.serviceEnabled} hasPermission=${recheck.hasPermission}');
        if (!recheck.hasPermission) {
          debugPrint('[GeofenceCubit] ⚠️ EARLY EXIT — location permission DENIED after request. User tapped "Don\'t Allow".');
          emit(state.copyWith(status: GeofenceCubitStatus.permissionDenied));
          return;
        }
        debugPrint('[GeofenceCubit] ✅ Permission granted after request');
      } else {
        debugPrint('[GeofenceCubit] ✅ Permission already granted — skipping request');
        // Permission already granted — _requestAllPermissions was skipped, so
        // the notification plugin may not have been initialised yet.
        unawaited(_ensureNotificationsInitialised());
      }

      emit(state.copyWith(status: GeofenceCubitStatus.fetchingSchoolLocation));

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
          ),
        );
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
        ),
      );
      if (immediateGeofenceStatus != null) {
        _triggerNotificationIfNeeded(
          immediateGeofenceStatus,
          fireFlutterNotification: isRefresh,
        );
      }

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
          errorMessage: e.toString(),
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
          _triggerNotificationIfNeeded(geofenceStatus);
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
          final newGeofenceStatus = isInside
              ? GeofenceStatus.within
              : GeofenceStatus.outside;
          _triggerNotificationIfNeeded(newGeofenceStatus);
        }
      },
      onError: (Object e) {
        AppLogger.d('[GeofenceCubit] Native event stream error: $e');
      },
    );
  }

  void _triggerNotificationIfNeeded(
    GeofenceStatus newStatus, {
    bool fireFlutterNotification = false,
  }) {
    if (_lastNotifiedStatus == newStatus) return;
    _lastNotifiedStatus = newStatus;

    // On an actual zone crossing the native layer fires the notification
    // (Android → GeofenceBroadcastReceiver, iOS → GeofencePlugin). On a
    // dashboard refresh there is no boundary crossing so native is silent —
    // fire the Flutter-side notification instead to inform the user.
    if (fireFlutterNotification) {
      if (newStatus == GeofenceStatus.within) {
        unawaited(_notifications.showEnteredZoneNotification());
      } else {
        unawaited(_notifications.showExitedZoneNotification());
      }
    }

    unawaited(
      SharedPreferences.getInstance()
          .then((prefs) async {
            await prefs.setString(_prefsLastGeofenceStatusKey, newStatus.name);
            await prefs.setBool(
              _prefsLastNotifiedInsideKey,
              newStatus == GeofenceStatus.within,
            );
          })
          .catchError((_) {}),
    );
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
        _triggerNotificationIfNeeded(
          isInside ? GeofenceStatus.within : GeofenceStatus.outside,
        );
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
    _lastNotifiedStatus = null;
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

  Future<void> checkStaffSignInStatus() async {
    try {
      final storage = serviceLocator<StorageService>();
      final staffCode = await storage.getString(StorageKeys.staffCode);
      if (staffCode == null || staffCode.isEmpty) {
        emit(state.copyWith(isStaffSignedIn: false));
        return;
      }
      final getStaffStatusUseCase = serviceLocator<GetStaffTodaySignInStatusUseCase>();
      final status = await getStaffStatusUseCase(staffCode: staffCode);
      final isSignedIn = status?.toUpperCase() == 'SIGNED_IN';
      emit(state.copyWith(isStaffSignedIn: isSignedIn));
    } catch (_) {
      emit(state.copyWith(isStaffSignedIn: false));
    }
  }

  Future<void> updateStaffSignInStatus(bool isSignedIn) async {
    emit(state.copyWith(isStaffSignedIn: isSignedIn));
  }

  @override
  Future<void> close() {
    stopMonitoring();
    return super.close();
  }
}
