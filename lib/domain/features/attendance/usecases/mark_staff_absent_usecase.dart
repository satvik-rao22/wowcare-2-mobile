import 'package:wowcare/core/util/api_error_handler.dart';
import '../repositories/attendance_repository.dart';

class MarkStaffAbsentUseCase {
  MarkStaffAbsentUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<String> call({
    required String staffCode,
    required List<String> staffCodes,
    required String absenceFromDate,
    required String absenceToDate,
    required String absenceReason,
    required String absenceType,
    required Map<String, String> absenceNotes,
  }) async {
    try {
      return await _repository.markStaffAbsent(
        staffCode: staffCode,
        staffCodes: staffCodes,
        absenceFromDate: absenceFromDate,
        absenceToDate: absenceToDate,
        absenceReason: absenceReason,
        absenceType: absenceType,
        absenceNotes: absenceNotes,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

