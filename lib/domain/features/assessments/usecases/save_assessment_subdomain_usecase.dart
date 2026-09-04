import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class SaveAssessmentSubdomainUseCase {
  const SaveAssessmentSubdomainUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<AssessmentSubdomain> call(AssessmentSubdomain subdomain) =>
      _repository.saveSubdomain(subdomain);
}
