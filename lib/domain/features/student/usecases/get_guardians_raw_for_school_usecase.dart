import '../entities/school_guardian_summary.dart';
import '../repositories/student_repository.dart';

class GetGuardiansRawForSchoolUseCase {
  GetGuardiansRawForSchoolUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<SchoolGuardianSummary>> call({required String schoolCode}) {
    return _repository.getGuardiansRawForSchool(schoolCode: schoolCode);
  }
}
