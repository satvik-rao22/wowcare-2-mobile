import '../entities/classroom.dart';
import '../repositories/classroom_repository.dart';

class GetClassroomsUseCase {
  GetClassroomsUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<ClassroomPage> call({
    required String schoolCode,
    int page = 0,
    int size = 10,
  }) {
    return _repository.getClassrooms(
      schoolCode: schoolCode,
      page: page,
      size: size,
    );
  }
}


