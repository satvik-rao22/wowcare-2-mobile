part of 'geofence_cubit.dart';

enum GeofenceCubitStatus {
  initial,
  checkingPermission,
  permissionDenied,
  locationDisabled,
  fetchingSchoolLocation,
  checking,
  withinRange,
  outsideRange,
  /// Admin disabled GPS sign-in via attendance settings.
  gpsDisabledByAdmin,
  error,
}

class GeofenceState extends Equatable {
  const GeofenceState({
    required this.status,
    this.schoolCode = '',
    this.errorMessage = '',
    this.distanceMeters,
    this.radiusMeters,
    this.gpsSignInEnabled = true,
    this.parentGpsSignInEnabled = true,
    this.isStaffSignedIn = false,
    this.permissionLevel = LocationPermissionLevel.denied,
  });

  const GeofenceState.initial()
      : status = GeofenceCubitStatus.initial,
        schoolCode = '',
        errorMessage = '',
        distanceMeters = null,
        radiusMeters = null,
        gpsSignInEnabled = true,
        parentGpsSignInEnabled = true,
        isStaffSignedIn = false,
        permissionLevel = LocationPermissionLevel.denied;

  final GeofenceCubitStatus status;
  final String schoolCode;
  final String errorMessage;

  /// Live distance to school centre in metres (updated on each GPS fix).
  final double? distanceMeters;

  /// Geofence radius fetched from attendance-settings API.
  final double? radiusMeters;

  /// Mirrors [GeofenceConfig.gpsSignInEnabled] — false when admin turned off GPS attendance.
  final bool gpsSignInEnabled;

  /// Mirrors [GeofenceConfig.parentGpsSignInEnabled] — false when parent GPS
  /// sign-in is specifically disabled by the school admin.
  final bool parentGpsSignInEnabled;

  /// Tracks if the staff member themselves has signed in.
  final bool isStaffSignedIn;

  /// Normalized OS location permission level. Internal plumbing only — does
  /// not currently drive any gating; [isWithinGeofence]/[status] remain the
  /// source of truth for Sign-In availability.
  final LocationPermissionLevel permissionLevel;

  /// True only when within range AND admin has GPS sign-in enabled.
  bool get isWithinGeofence =>
      status == GeofenceCubitStatus.withinRange && gpsSignInEnabled;

  bool get isLocationEnabled =>
      status == GeofenceCubitStatus.withinRange ||
      status == GeofenceCubitStatus.outsideRange ||
      status == GeofenceCubitStatus.checking;

  GeofenceState copyWith({
    GeofenceCubitStatus? status,
    String? schoolCode,
    String? errorMessage,
    double? distanceMeters,
    double? radiusMeters,
    bool? gpsSignInEnabled,
    bool? parentGpsSignInEnabled,
    bool? isStaffSignedIn,
    LocationPermissionLevel? permissionLevel,
  }) =>
      GeofenceState(
        status: status ?? this.status,
        schoolCode: schoolCode ?? this.schoolCode,
        errorMessage: errorMessage ?? this.errorMessage,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        gpsSignInEnabled: gpsSignInEnabled ?? this.gpsSignInEnabled,
        parentGpsSignInEnabled:
            parentGpsSignInEnabled ?? this.parentGpsSignInEnabled,
        isStaffSignedIn: isStaffSignedIn ?? this.isStaffSignedIn,
        permissionLevel: permissionLevel ?? this.permissionLevel,
      );

  @override
  List<Object?> get props => [
        status,
        schoolCode,
        errorMessage,
        distanceMeters,
        radiusMeters,
        gpsSignInEnabled,
        parentGpsSignInEnabled,
        isStaffSignedIn,
        permissionLevel,
      ];
}
