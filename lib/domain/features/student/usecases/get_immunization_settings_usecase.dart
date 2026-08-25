import '../entities/vaccine_item.dart';
import '../repositories/student_repository.dart';

/// Fetches available vaccines / immunization settings for a school.
class GetImmunizationSettingsUseCase {
  GetImmunizationSettingsUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<VaccineItem>> call({required String schoolCode}) {
    return _repository.getImmunizationSettings(schoolCode: schoolCode);
  }
}
