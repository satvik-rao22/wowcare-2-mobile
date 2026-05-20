import '../repositories/staff_scheduling_repository.dart';

class GetAllClassroomsUseCase {
  final StaffSchedulingRepository _repository;

  GetAllClassroomsUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call(String schoolCode) {
    return _repository.getAllClassrooms(schoolCode);
  }
}

