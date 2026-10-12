import 'package:wowcare/core/observability/app_events.dart';

import '../entities/location_permission_level.dart';
import '../repositories/geofencing_repository.dart';

class RequestLocationPermissionUseCase {
  const RequestLocationPermissionUseCase(this._repository);
  final GeofencingRepository _repository;

  /// Requests foreground ("While Using the App") location permission only —
  /// never requests background/"Always" automatically.
  ///
  /// Logged failed with [EventFailure.permission] when the user or the OS
  /// denies it, now or for good.
  Future<LocationPermissionLevel> call() => AppEvents.track(
    AppEvent.geofencePermissionRequest,
    () => _repository.requestLocationPermission(),
    failureOf: _failureOf,
  );

  /// Any granted level, foreground or background, is a success.
  static EventFailure? _failureOf(LocationPermissionLevel level) =>
      switch (level) {
        LocationPermissionLevel.whileInUse ||
        LocationPermissionLevel.always => null,
        LocationPermissionLevel.denied ||
        LocationPermissionLevel.permanentlyDenied => EventFailure.permission,
      };
}
