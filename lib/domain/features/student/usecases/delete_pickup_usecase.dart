import '../repositories/student_repository.dart';

class DeletePickupUseCase {
  DeletePickupUseCase(this._repository);

  final StudentRepository _repository;

  Future<String> call({required String code, required String studentCode}) {
    return _repository.deletePickup(code: code, studentCode: studentCode);
  }
}
