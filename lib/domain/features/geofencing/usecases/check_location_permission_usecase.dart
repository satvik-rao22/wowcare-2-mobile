import '../repositories/geofencing_repository.dart';

class CheckLocationPermissionUseCase {
  const CheckLocationPermissionUseCase(this._repository);
  final GeofencingRepository _repository;

  Future<({bool hasPermission, bool serviceEnabled})> call() async {
    final serviceEnabled = await _repository.isLocationServiceEnabled();
    final hasPermission = await _repository.hasLocationPermission();
    return (hasPermission: hasPermission, serviceEnabled: serviceEnabled);
  }
}
