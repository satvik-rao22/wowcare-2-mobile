import 'package:geolocator/geolocator.dart';
import '../entities/geofence_config.dart';
import '../entities/geofence_status.dart';
import '../repositories/geofencing_repository.dart';

class WatchGeofenceUseCase {
  const WatchGeofenceUseCase(this._repository);
  final GeofencingRepository _repository;

  Stream<GeofenceStatus> call({required GeofenceConfig config}) {
    const hysteresisExitMeters = 50.0;
    return _repository
        .getPositionStream()
        .map((position) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            config.latitude,
            config.longitude,
          );
          // Enter immediately; exit only when confidently beyond radius + hysteresis buffer
          if (distance <= config.radiusMeters) return GeofenceStatus.within;
          final accuracy = position.accuracy.clamp(0.0, double.infinity);
          final confidentlyOutside =
              distance - accuracy > config.radiusMeters + hysteresisExitMeters;
          return confidentlyOutside ? GeofenceStatus.outside : null;
        })
        .where((status) => status != null)
        .cast<GeofenceStatus>();
  }
}
