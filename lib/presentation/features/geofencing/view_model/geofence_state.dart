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

/// Outcome of [GeofenceCubit.checkAtSchoolNow].
enum AtSchoolCheck {
  atSchool,
  notAtSchool,

  /// The phone's Location (GPS) switch is off.
  gpsOff,
  noPermission,

  /// The school admin turned GPS sign-in off.
  gpsSignInOff,

  /// No GPS fix within the time limit.
  locationUnavailable,

  /// The position came from a fake-GPS (mock location) app.
  fakeLocation,

  /// School location isn't loaded (no school, or the API failed).
  notReady,
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
    this.locationPermission = AppPermissionStatus.denied,
    this.allChildrenSignedIn = false,
    this.isSignInStatusLoading = false,
    this.refreshNonce = 0,
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
      locationPermission = AppPermissionStatus.denied,
      allChildrenSignedIn = false,
      isSignInStatusLoading = false,
      refreshNonce = 0;

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

  /// Guardian/parent equivalent of [isStaffSignedIn]: true only when the
  /// guardian has at least one child AND every one of them is already
  /// signed in for the day — used to suppress the "you can now Sign In or
  /// Sign Out" notification when there's nothing left to act on.
  final bool allChildrenSignedIn;

  /// Location permission as last read from the OS. Internal plumbing only —
  /// [status] remains the source of truth for Sign-In availability.
  final AppPermissionStatus locationPermission;

  /// True when the sign-in status is actively being fetched.
  final bool isSignInStatusLoading;

  /// Explicit Flutter-side token that increments whenever a manual dashboard
  /// refresh occurs, so the UI can clear its sign-in reminder dedup flag and
  /// reliably re-evaluate showing the reminder if the user is inside + not signed in.
  final int refreshNonce;

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
    AppPermissionStatus? locationPermission,
    bool? allChildrenSignedIn,
    bool? isSignInStatusLoading,
    int? refreshNonce,
  }) => GeofenceState(
    status: status ?? this.status,
    schoolCode: schoolCode ?? this.schoolCode,
    errorMessage: errorMessage ?? this.errorMessage,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    gpsSignInEnabled: gpsSignInEnabled ?? this.gpsSignInEnabled,
    parentGpsSignInEnabled:
        parentGpsSignInEnabled ?? this.parentGpsSignInEnabled,
    isStaffSignedIn: isStaffSignedIn ?? this.isStaffSignedIn,
    locationPermission: locationPermission ?? this.locationPermission,
    allChildrenSignedIn: allChildrenSignedIn ?? this.allChildrenSignedIn,
    isSignInStatusLoading: isSignInStatusLoading ?? this.isSignInStatusLoading,
    refreshNonce: refreshNonce ?? this.refreshNonce,
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
    locationPermission,
    allChildrenSignedIn,
    isSignInStatusLoading,
    refreshNonce,
  ];
}
