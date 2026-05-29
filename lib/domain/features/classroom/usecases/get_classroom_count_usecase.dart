import '../entities/classroom_count.dart';
import '../repositories/classroom_repository.dart';

class GetClassroomCountUseCase {
  GetClassroomCountUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<ClassroomCount> call({required String schoolCode, String status = 'ACTIVE'}) {
    return _repository.getClassroomCount(schoolCode: schoolCode, status: status);
  }
}
