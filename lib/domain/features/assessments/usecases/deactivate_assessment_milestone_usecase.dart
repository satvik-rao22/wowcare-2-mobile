import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class DeactivateAssessmentMilestoneUseCase {
  const DeactivateAssessmentMilestoneUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<void> call(String milestoneId) =>
      _repository.deactivateMilestone(milestoneId);
}
