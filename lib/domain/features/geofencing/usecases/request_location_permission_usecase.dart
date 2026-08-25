import '../entities/location_permission_level.dart';
import '../repositories/geofencing_repository.dart';

class RequestLocationPermissionUseCase {
  const RequestLocationPermissionUseCase(this._repository);
  final GeofencingRepository _repository;

  /// Requests foreground ("While Using the App") location permission only —
  /// never requests background/"Always" automatically.
  Future<LocationPermissionLevel> call() =>
      _repository.requestLocationPermission();
}
