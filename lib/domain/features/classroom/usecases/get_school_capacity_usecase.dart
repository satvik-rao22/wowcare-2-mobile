import '../entities/school_capacity.dart';
import '../repositories/classroom_repository.dart';

class GetSchoolCapacityUseCase {
  GetSchoolCapacityUseCase(this._repository);

  final ClassroomRepository _repository;

  Future<SchoolCapacity> call({required String schoolCode}) {
    return _repository.getSchoolCapacity(schoolCode: schoolCode);
  }
}
