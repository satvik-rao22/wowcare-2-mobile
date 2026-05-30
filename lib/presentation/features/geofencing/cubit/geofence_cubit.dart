import 'package:wowcare/core/util/logger_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../domain/features/geofencing/entities/geofence_config.dart';
import '../../../../domain/features/geofencing/entities/geofence_status.dart';
import '../../../../domain/features/geofencing/usecases/check_location_permission_usecase.dart';
import '../../../../domain/features/geofencing/usecases/get_school_location_usecase.dart';
import '../../../../domain/features/geofencing/usecases/request_location_permission_usecase.dart';
import '../../../../domain/features/geofencing/usecases/watch_geofence_usecase.dart';
import '../../../../shared/services/geofence_notification_service.dart';

part 'geofence_state.dart';

class GeofenceCubit extends Cubit<GeofenceState> {
  static const _nativeGeofenceChannel = MethodChannel('com.wowcare.geofencing/native');

  GeofenceCubit({
    required CheckLocationPermissionUseCase checkLocationPermissionUseCase,
    required RequestLocationPermissionUseCase requestLocationPermissionUseCase,
    required GetSchoolLocationUseCase getSchoolLocationUseCase,
    required WatchGeofenceUseCase watchGeofenceUseCase,
    required GeofenceNotificationService notificationService,
  })  : _checkPerm = checkLocationPermissionUseCase,
        _requestPerm = requestLocationPermissionUseCase,
        _getSchoolLocation = getSchoolLocationUseCase,
        _watchGeofence = watchGeofenceUseCase,
        _notifications = notificationService,
        super(const GeofenceState.initial());

  final CheckLocationPermissionUseCase _checkPerm;
  final RequestLocationPermissionUseCase _requestPerm;
  final GetSchoolLocationUseCase _getSchoolLocation;
  final WatchGeofenceUseCase _watchGeofence;
  final GeofenceNotificationService _notifications;

  StreamSubscription<GeofenceStatus>? _subscription;
  GeofenceStatus? _lastNotifiedStatus;
  GeofenceConfig? _config;

  Future<void> initForSchool({required String schoolCode}) async {
    AppLogger.d('[GeofenceCubit] initForSchool called with schoolCode: $schoolCode');
    if (state.schoolCode == schoolCode &&
        (state.status == GeofenceCubitStatus.withinRange ||
            state.status == GeofenceCubitStatus.outsideRange)) {
      AppLogger.d('[GeofenceCubit] Already monitoring this school, skipping init');
      return;
    }

    stopMonitoring();
    emit(GeofenceState(
      status: GeofenceCubitStatus.checkingPermission,
      schoolCode: schoolCode,
    ));
    AppLogger.d('[GeofenceCubit] Emitted checkingPermission status');

    await _checkAndStartMonitoring(schoolCode: schoolCode);
  }

  Future<void> retryPermission() async {
    final schoolCode = state.schoolCode;
    if (schoolCode.isEmpty) return;
    AppLogger.d('[GeofenceCubit] retryPermission called');
    await _requestAllPermissions();
    await _checkAndStartMonitoring(schoolCode: schoolCode);
  }

  /// Request all required permissions (location + notifications)
  Future<void> _requestAllPermissions() async {
    AppLogger.d('[GeofenceCubit] Requesting all required permissions');

    // Request Location Permission
    AppLogger.d('[GeofenceCubit] Requesting LOCATION permission');
    await _requestPerm();

    // Request Notification Permission (Android 13+)
    if (Platform.isAndroid) {
      AppLogger.d('[GeofenceCubit] Requesting NOTIFICATION permission');
      try {
        final notificationStatus = await Permission.notification.request();
        AppLogger.d('[GeofenceCubit] Notification permission: $notificationStatus');
      } catch (e) {
        AppLogger.d('[GeofenceCubit] Error requesting notification permission: $e');
      }
    }
  }

  Future<void> _checkAndStartMonitoring({required String schoolCode}) async {
    try {
      AppLogger.d('[GeofenceCubit] _checkAndStartMonitoring started');
      final permCheck = await _checkPerm();
      AppLogger.d('[GeofenceCubit] permCheck - hasPermission: ${permCheck.hasPermission}, serviceEnabled: ${permCheck.serviceEnabled}');

      if (!permCheck.serviceEnabled) {
        AppLogger.d('[GeofenceCubit] Location services disabled');
        emit(state.copyWith(status: GeofenceCubitStatus.locationDisabled));
        return;
      }
      if (!permCheck.hasPermission) {
        AppLogger.d('[GeofenceCubit] Requesting all permissions (location + notifications)');
        await _requestAllPermissions();

        // Re-check after permission request
        final permCheckAgain = await _checkPerm();
        AppLogger.d('[GeofenceCubit] Permission check after request: ${permCheckAgain.hasPermission}');
        if (!permCheckAgain.hasPermission) {
          emit(state.copyWith(status: GeofenceCubitStatus.permissionDenied));
          return;
        }
      }

      AppLogger.d('[GeofenceCubit] 🏫 Fetching school location for schoolCode: "$schoolCode"');
      AppLogger.d('[GeofenceCubit] API Call: GET /api/v1/schools/$schoolCode/timezone');
      emit(state.copyWith(status: GeofenceCubitStatus.fetchingSchoolLocation));
      _config = await _getSchoolLocation(schoolCode: schoolCode);
      AppLogger.d('[GeofenceCubit] ✅ School location fetched: schoolCode=${_config?.schoolCode}, lat=${_config?.latitude}, lon=${_config?.longitude}');

      // Cache school coordinates for background task and notify iOS native plugin
      if (_config != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('geofence_school_lat', _config!.latitude);
        await prefs.setDouble('geofence_school_lon', _config!.longitude);

        // iOS: Initialize native region monitoring
        await _updateNativeGeofence(_config!);
      }

      emit(state.copyWith(status: GeofenceCubitStatus.checking));
      _startStream();
    } catch (e) {
      AppLogger.d('[GeofenceCubit] ❌ ERROR during initialization: $e');
      AppLogger.d('[GeofenceCubit] Error type: ${e.runtimeType}');
      AppLogger.d('[GeofenceCubit] Full stack trace: ${StackTrace.current}');
      emit(state.copyWith(
        status: GeofenceCubitStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _startStream() {
    if (_config == null) {
      AppLogger.d('[GeofenceCubit] _startStream skipped: _config is null');
      return;
    }
    final config = _config!;
    AppLogger.d('[GeofenceCubit] _startStream starting with config: schoolCode=${config.schoolCode}, lat=${config.latitude}, lon=${config.longitude}, radius=${config.radiusMeters}m');

    _subscription = _watchGeofence(config: config)
        .distinct((prev, curr) {
          final isSame = prev == curr;
          if (!isSame) {
            AppLogger.d('[GeofenceCubit] distinct() found change: $prev → $curr');
          }
          return isSame;
        })
        .listen(
          (geofenceStatus) {
            AppLogger.d('[GeofenceCubit] ✅ Position stream emitted status: $geofenceStatus');
            final newCubitStatus = geofenceStatus == GeofenceStatus.within
                ? GeofenceCubitStatus.withinRange
                : GeofenceCubitStatus.outsideRange;

            AppLogger.d('[GeofenceCubit] Current state status: ${state.status}, new status: $newCubitStatus');

            if (state.status != newCubitStatus) {
              AppLogger.d('[GeofenceCubit] 🔄 STATE CHANGE: Emitting $newCubitStatus');
              emit(state.copyWith(status: newCubitStatus));
              _triggerNotificationIfNeeded(geofenceStatus);
            } else {
              AppLogger.d('[GeofenceCubit] ℹ️  Status unchanged, no emit needed');
            }
          },
          onError: (Object e) {
            AppLogger.d('[GeofenceCubit] ❌ Stream error: $e');
            emit(state.copyWith(
              status: GeofenceCubitStatus.error,
              errorMessage: e.toString(),
            ));
          },
        );
  }

  void _triggerNotificationIfNeeded(GeofenceStatus newStatus) {
    if (_lastNotifiedStatus == newStatus) return;
    _lastNotifiedStatus = newStatus;

    if (newStatus == GeofenceStatus.within) {
      _notifications.showEnteredZoneNotification().catchError((e) {
        AppLogger.d('Failed to show entered zone notification: $e');
      });
    } else if (newStatus == GeofenceStatus.outside &&
        _lastNotifiedStatus != null) {
      _notifications.showExitedZoneNotification().catchError((e) {
        AppLogger.d('Failed to show exited zone notification: $e');
      });
    }
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _lastNotifiedStatus = null;
  }

  Future<void> _updateNativeGeofence(GeofenceConfig config) async {
    if (!Platform.isIOS) return;

    try {
      await _nativeGeofenceChannel.invokeMethod('updateSchoolLocation', {
        'latitude': config.latitude,
        'longitude': config.longitude,
        'schoolCode': config.schoolCode,
        'radiusMeters': config.radiusMeters,
      });
    } catch (e) {
      AppLogger.d('Error updating native geofence: $e');
    }
  }

  @override
  Future<void> close() {
    stopMonitoring();
    return super.close();
  }
}
