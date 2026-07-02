import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class DeactivateAssessmentAgeGroupUseCase {
  const DeactivateAssessmentAgeGroupUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<void> call(String ageGroupId) =>
      _repository.deactivateAgeGroup(ageGroupId);
}
