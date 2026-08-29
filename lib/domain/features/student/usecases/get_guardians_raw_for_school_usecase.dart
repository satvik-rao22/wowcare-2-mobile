import '../repositories/student_repository.dart';

class GetGuardiansRawForSchoolUseCase {
  GetGuardiansRawForSchoolUseCase(this._repository);

  final StudentRepository _repository;

  Future<List<Map<String, dynamic>>> call({required String schoolCode}) {
    return _repository.getGuardiansRawForSchool(schoolCode: schoolCode);
  }
}
