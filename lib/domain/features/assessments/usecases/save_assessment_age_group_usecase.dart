import 'package:wowcare/domain/features/assessments/entities/assessment_age_group.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class SaveAssessmentAgeGroupUseCase {
  const SaveAssessmentAgeGroupUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<AssessmentAgeGroup> call(AssessmentAgeGroup ageGroup) =>
      _repository.saveAgeGroup(ageGroup);
}
