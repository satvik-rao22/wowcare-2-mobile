import '../entities/geofence_config.dart';
import '../repositories/geofencing_repository.dart';

class GetSchoolLocationUseCase {
  const GetSchoolLocationUseCase(this._repository);
  final GeofencingRepository _repository;

  Future<GeofenceConfig> call({required String schoolCode}) =>
      _repository.getSchoolLocation(schoolCode: schoolCode);
}
