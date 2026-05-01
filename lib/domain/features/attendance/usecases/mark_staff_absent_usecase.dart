import 'package:wowcare/core/util/api_error_handler.dart';
import '../repositories/attendance_repository.dart';

class MarkStaffAbsentUseCase {
  MarkStaffAbsentUseCase(this._repository);

  final AttendanceRepository _repository;

  /// Sends the full absence range selected in the form.
  Future<String> call({
    required String staffCode,
    required List<String> staffCodes,
    required String absenceFromDate,
    required String absenceToDate,
    required String absenceReason,
    required String absenceType,
    required Map<String, String> absenceNotes,
    required Map<String, bool> isExpectedTodayByStaffCode,
    String markAbsentMethod = 'APP',
  }) async {
    try {
      final parsedFrom = DateTime.parse(absenceFromDate);
      final parsedTo = DateTime.parse(absenceToDate);
      final startDay = DateTime(parsedFrom.year, parsedFrom.month, parsedFrom.day);
      final endDay = DateTime(parsedTo.year, parsedTo.month, parsedTo.day);
      if (endDay.isBefore(startDay)) {
        throw Exception('End date must be on or after start date');
      }
      return await _repository.markStaffAbsent(
        staffCode: staffCode,
        staffCodes: staffCodes,
        absenceFromDate: absenceFromDate,
        absenceToDate: absenceToDate,
        absenceReason: absenceReason,
        absenceType: absenceType,
        absenceNotes: absenceNotes,
        isExpectedTodayByStaffCode: isExpectedTodayByStaffCode,
        markAbsentMethod: markAbsentMethod,
      );
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

