import 'package:geolocator/geolocator.dart';
import '../entities/geofence_config.dart';
import '../entities/geofence_status.dart';
import '../repositories/geofencing_repository.dart';

class WatchGeofenceUseCase {
  const WatchGeofenceUseCase(this._repository);
  final GeofencingRepository _repository;

  Stream<GeofenceStatus> call({required GeofenceConfig config}) {
    return _repository.getPositionStream().map((position) {
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        config.latitude,
        config.longitude,
      );
      return distanceMeters <= config.radiusMeters
          ? GeofenceStatus.within
          : GeofenceStatus.outside;
    });
  }
}
