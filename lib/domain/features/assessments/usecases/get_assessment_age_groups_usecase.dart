import 'package:wowcare/domain/features/assessments/entities/assessment_age_group.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class GetAssessmentAgeGroupsUseCase {
  const GetAssessmentAgeGroupsUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<List<AssessmentAgeGroup>> call() => _repository.getAgeGroups();
}
