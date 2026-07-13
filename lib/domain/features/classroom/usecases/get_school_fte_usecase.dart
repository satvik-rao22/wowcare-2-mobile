import '../entities/school_fte.dart';
import '../repositories/classroom_repository.dart';

class GetSchoolFteUseCase {
  GetSchoolFteUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<SchoolFte> call({required String schoolCode, required int capacity}) {
    return _repository.getSchoolFte(schoolCode: schoolCode, capacity: capacity);
  }
}
