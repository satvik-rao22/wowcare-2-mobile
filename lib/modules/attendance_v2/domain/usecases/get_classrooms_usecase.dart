import '../entities/av2_classroom.dart';
import '../repositories/attendance_v2_repository.dart';

/// Loads active classrooms/locations for the add-attendance room pickers.
class GetClassroomsUseCase {
  GetClassroomsUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<List<Av2Classroom>> call() => _repository.getClassrooms();
}
