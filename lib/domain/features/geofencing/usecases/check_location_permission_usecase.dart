import '../entities/location_permission_level.dart';
import '../repositories/geofencing_repository.dart';

class CheckLocationPermissionUseCase {
  const CheckLocationPermissionUseCase(this._repository);
  final GeofencingRepository _repository;

  Future<({LocationPermissionLevel permissionLevel, bool serviceEnabled})>
  call() async {
    final serviceEnabled = await _repository.isLocationServiceEnabled();
    final permissionLevel = await _repository.getPermissionLevel();
    return (permissionLevel: permissionLevel, serviceEnabled: serviceEnabled);
  }
}
