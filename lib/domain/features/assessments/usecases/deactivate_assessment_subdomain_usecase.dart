import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class DeactivateAssessmentSubdomainUseCase {
  const DeactivateAssessmentSubdomainUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<void> call(String subdomainId) =>
      _repository.deactivateSubdomain(subdomainId);
}
