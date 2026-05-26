import 'package:geolocator/geolocator.dart';
import '../entities/geofence_config.dart';

abstract class GeofencingRepository {
  Future<bool> hasLocationPermission();
  Future<bool> requestLocationPermission();
  Future<bool> isLocationServiceEnabled();
  Future<GeofenceConfig> getSchoolLocation({required String schoolCode});
  Future<Position> getCurrentPosition();
  Stream<Position> getPositionStream();
}
