import '../repositories/student_repository.dart';

class DeletePhysicianUseCase {
  DeletePhysicianUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({required String code, required String studentCode}) {
    return _repository.deletePhysician(code: code, studentCode: studentCode);
  }
}
