import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class GetAssessmentClassroomsUseCase {
  const GetAssessmentClassroomsUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<List<AssessmentClassroom>> call() => _repository.getClassrooms();
}
