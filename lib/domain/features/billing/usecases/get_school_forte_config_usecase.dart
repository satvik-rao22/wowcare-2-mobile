import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Fetches the school's Forte config (`GET /school-forte-configs`).
class GetSchoolForteConfigUseCase {
  GetSchoolForteConfigUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<SchoolForteConfigEntity?> call({
    required String organizationCode,
    required String schoolCode,
  }) => _repository.getSchoolForteConfig(
    organizationCode: organizationCode,
    schoolCode: schoolCode,
  );
}
