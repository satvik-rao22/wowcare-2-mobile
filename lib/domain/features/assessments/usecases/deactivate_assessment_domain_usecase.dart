import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class DeactivateAssessmentDomainUseCase {
  const DeactivateAssessmentDomainUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<void> call(String domainId) => _repository.deactivateDomain(domainId);
}
