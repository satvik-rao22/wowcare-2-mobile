import '../entities/classroom_details.dart';
import '../repositories/classroom_repository.dart';

class GetClassroomByCodeUseCase {
  GetClassroomByCodeUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<ClassroomDetails> call({required String code}) {
    return _repository.getClassroomByCode(code: code);
  }
}
