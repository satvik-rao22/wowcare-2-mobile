import 'package:wowcare/core/observability/app_events.dart';

import '../../../../core/utils/api_error_handler.dart';
import '../repositories/student_classroom_repository.dart';

class AssignStudentsToClassroomUseCase {
  AssignStudentsToClassroomUseCase(this._repository);

  final StudentClassroomRepository _repository;

  Future<String> call({
    required String schoolCode,
    required String classroomCode,
    required List<String> studentCodes,
  }) async {
    try {
      return await AppEvents.track(
        AppEvent.studentClassroomAssign,
        () => _repository.assignStudentsToClassroom(
          schoolCode: schoolCode,
          classroomCode: classroomCode,
          studentCodes: studentCodes,
        ),
        count: studentCodes.length,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

