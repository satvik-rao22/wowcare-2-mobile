import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class UpdateMilestoneAgeGroupsUseCase {
  const UpdateMilestoneAgeGroupsUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<AssessmentMilestone> call(
    String milestoneId,
    List<String> ageGroupIds,
  ) =>
      _repository.updateMilestoneAgeGroups(milestoneId, ageGroupIds);
}
