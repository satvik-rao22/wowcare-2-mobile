import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class GetAssessmentDomainsUseCase {
  const GetAssessmentDomainsUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<List<AssessmentDomain>> call() => _repository.getDomains();
}
