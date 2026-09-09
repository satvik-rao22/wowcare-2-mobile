import '../repositories/student_repository.dart';

class DeleteGuardianUseCase {
  DeleteGuardianUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({required String code, required String studentCode}) {
    return _repository.deleteGuardian(code: code, studentCode: studentCode);
  }
}
