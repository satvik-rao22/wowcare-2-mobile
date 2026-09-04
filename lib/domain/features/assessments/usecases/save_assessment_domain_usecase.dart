import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class SaveAssessmentDomainUseCase {
  const SaveAssessmentDomainUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<AssessmentDomain> call(AssessmentDomain domain) =>
      _repository.saveDomain(domain);
}
