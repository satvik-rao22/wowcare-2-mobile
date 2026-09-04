import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class GetAssessmentsUseCase {
  const GetAssessmentsUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<List<Assessment>> call() => _repository.getAssessments();
}
