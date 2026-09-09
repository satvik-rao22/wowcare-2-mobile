import '../repositories/staff_repository.dart';

/// Use case to update a staff member's allowed classrooms.
class UpdateStaffAllowedClassroomsUseCase {
  UpdateStaffAllowedClassroomsUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String staffCode,
    required List<String> classroomCodes,
  }) {
    return _repository.updateStaffAllowedClassrooms(
      staffCode: staffCode,
      classroomCodes: classroomCodes,
    );
  }
}
