import '../repositories/geofencing_repository.dart';

class RequestLocationPermissionUseCase {
  const RequestLocationPermissionUseCase(this._repository);
  final GeofencingRepository _repository;

  Future<bool> call() => _repository.requestLocationPermission();
}
