import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';

import '../repositories/attendance_repository.dart';

class UpdateStudentAttendanceRecordUseCase {
  UpdateStudentAttendanceRecordUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<String> call({
    required String attendanceRecordCode,
    required String staffCode,
    DateTime? signedInAt,
    DateTime? signedOutAt,
    String? originalClassroomCode,
    String? currentClassroomCode,
    String? notes,
    String? timeZone,
  }) async {
    try {
      return await AppEvents.track(
        AppEvent.attendanceStudentRecordUpdate,
        () => _repository.updateStudentAttendanceRecord(
          attendanceRecordCode: attendanceRecordCode,
          staffCode: staffCode,
          signedInAt: signedInAt,
          signedOutAt: signedOutAt,
          originalClassroomCode: originalClassroomCode,
          currentClassroomCode: currentClassroomCode,
          notes: notes,
          timeZone: timeZone,
        ),
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

