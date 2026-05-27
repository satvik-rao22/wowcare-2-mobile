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
  error,
}

class GeofenceState extends Equatable {
  const GeofenceState({
    required this.status,
    this.schoolCode = '',
    this.errorMessage = '',
    this.lastCheckedDistance,
  });

  const GeofenceState.initial()
      : status = GeofenceCubitStatus.initial,
        schoolCode = '',
        errorMessage = '',
        lastCheckedDistance = null;

  final GeofenceCubitStatus status;
  final String schoolCode;
  final String errorMessage;
  final double? lastCheckedDistance;

  bool get isWithinGeofence => status == GeofenceCubitStatus.withinRange;

  bool get isLocationEnabled =>
      status == GeofenceCubitStatus.withinRange ||
      status == GeofenceCubitStatus.outsideRange ||
      status == GeofenceCubitStatus.checking;

  GeofenceState copyWith({
    GeofenceCubitStatus? status,
    String? schoolCode,
    String? errorMessage,
    double? lastCheckedDistance,
  }) =>
      GeofenceState(
        status: status ?? this.status,
        schoolCode: schoolCode ?? this.schoolCode,
        errorMessage: errorMessage ?? this.errorMessage,
        lastCheckedDistance: lastCheckedDistance ?? this.lastCheckedDistance,
      );

  @override
  List<Object?> get props =>
      [status, schoolCode, errorMessage, lastCheckedDistance];
}
