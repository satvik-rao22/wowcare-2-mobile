import 'package:wowcare/core/util/api_error_handler.dart';
import '../repositories/attendance_repository.dart';

class MarkStudentsAbsentUseCase {
  MarkStudentsAbsentUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<String> call({
    required String staffCode,
    required List<String> studentCodes,
    required String absenceFromDate,
    required String absenceToDate,
    required String absenceReason,
    required Map<String, String> absenceNotes,
    required String classroomCode,
  }) async {
    try {
      return await _repository.markStudentsAbsent(
        staffCode: staffCode,
        studentCodes: studentCodes,
        absenceFromDate: absenceFromDate,
        absenceToDate: absenceToDate,
        absenceReason: absenceReason,
        absenceNotes: absenceNotes,
        classroomCode: classroomCode,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

