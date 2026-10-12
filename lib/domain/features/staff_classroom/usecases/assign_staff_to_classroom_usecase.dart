import 'package:wowcare/core/observability/app_events.dart';
import '../../../../core/utils/api_error_handler.dart';
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
      return await AppEvents.track(
        AppEvent.staffClassroomAssign,
        () => _repository.assignStaffToClassroom(
          schoolCode: schoolCode,
          classroomCode: classroomCode,
          staffCodes: staffCodes,
        ),
        count: staffCodes.length,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

