import '../../../../core/util/api_error_handler.dart';
import '../repositories/staff_classroom_repository.dart';

class AssignStaffToClassroomUseCase {
  AssignStaffToClassroomUseCase(this._repository);

  final StaffClassroomRepository _repository;

  Future<String> call({
    required String schoolCode,
    required String classroomCode,
    required List<String> staffCodes,
  }) async {
    try {
      return await _repository.assignStaffToClassroom(
        schoolCode: schoolCode,
        classroomCode: classroomCode,
        staffCodes: staffCodes,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

