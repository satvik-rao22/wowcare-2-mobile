import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/domain/features/assessments/repositories/assessment_repository.dart';

class GetAssessmentStudentsUseCase {
  const GetAssessmentStudentsUseCase(this._repository);

  final AssessmentRepository _repository;

  Future<List<AssessmentStudent>> call() => _repository.getStudents();
}
