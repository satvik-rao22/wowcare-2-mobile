import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class SaveAssessmentMilestoneUseCase {
  const SaveAssessmentMilestoneUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<AssessmentMilestone> call(AssessmentMilestone milestone) =>
      _repository.saveMilestone(milestone);
}
