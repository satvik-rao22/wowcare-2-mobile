import 'package:equatable/equatable.dart';

/// Runtime geofence configuration built from two backend sources:
///   - lat/lon  → GET /api/v1/schools/{schoolCode}/timezone
///   - radius + flags → GET /api/v1/attendance/schools/{schoolCode}/attendance-settings
///
/// Never hardcode [radiusMeters]. Always derive it from the attendance-settings API.
class GeofenceConfig extends Equatable {
  const GeofenceConfig({
    required this.schoolCode,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.gpsSignInEnabled = true,
    this.parentGpsSignInEnabled = true,
    this.autoSignOutEnabled = false,
    this.autoSignOutDelayMinutes = 0,
  });

  final String schoolCode;
  final double latitude;
  final double longitude;

  /// Geofence enter radius from `proximityRadiusMeters` in attendance-settings.
  final double radiusMeters;

  /// When false the sign-in button must be disabled regardless of GPS position.
  final bool gpsSignInEnabled;

  /// When false, parents specifically cannot sign in via GPS.
  final bool parentGpsSignInEnabled;

  final bool autoSignOutEnabled;
  final int autoSignOutDelayMinutes;

  @override
  List<Object?> get props => [
    schoolCode,
    latitude,
    longitude,
    radiusMeters,
    gpsSignInEnabled,
    parentGpsSignInEnabled,
    autoSignOutEnabled,
    autoSignOutDelayMinutes,
  ];
}
