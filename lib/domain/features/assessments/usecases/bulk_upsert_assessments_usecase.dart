import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

/// "Save All Assessments" (PRD FR-SA-12). Transactional bulk upsert.
class BulkUpsertAssessmentsUseCase {
  const BulkUpsertAssessmentsUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<List<Assessment>> call(List<Assessment> assessments) =>
      _repository.bulkUpsertAssessments(assessments);
}
