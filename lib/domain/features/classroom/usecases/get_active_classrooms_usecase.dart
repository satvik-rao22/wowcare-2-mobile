import '../entities/classroom.dart';
import '../repositories/classroom_repository.dart';

class GetActiveClassroomsUseCase {
  GetActiveClassroomsUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<List<Classroom>> call({
    required String schoolCode,
    bool onlyTypeClassroom = true,
    String? typeOverride,
  }) {
    return _repository.getActiveClassrooms(
      schoolCode: schoolCode,
      onlyTypeClassroom: onlyTypeClassroom,
      typeOverride: typeOverride,
    );
  }
}

