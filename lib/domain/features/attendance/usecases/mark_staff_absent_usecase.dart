import 'package:wowcare/core/util/api_error_handler.dart';
import '../repositories/attendance_repository.dart';

class MarkStaffAbsentUseCase {
  MarkStaffAbsentUseCase(this._repository);

  final AttendanceRepository _repository;

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Backend expects one POST per calendar day; expands [absenceFromDate]–[absenceToDate] inclusive.
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
      var day = DateTime(parsedFrom.year, parsedFrom.month, parsedFrom.day);
      final endDay = DateTime(parsedTo.year, parsedTo.month, parsedTo.day);
      if (endDay.isBefore(day)) {
        throw Exception('End date must be on or after start date');
      }

      String lastMessage = '';
      for (; !day.isAfter(endDay); day = day.add(const Duration(days: 1))) {
        final dayStr = _ymd(day);
        try {
          lastMessage = await _repository.markStaffAbsent(
            staffCode: staffCode,
            staffCodes: staffCodes,
            absenceFromDate: dayStr,
            absenceToDate: dayStr,
            absenceReason: absenceReason,
            absenceType: absenceType,
            absenceNotes: absenceNotes,
            isExpectedTodayByStaffCode: isExpectedTodayByStaffCode,
            markAbsentMethod: markAbsentMethod,
          );
        } catch (e) {
          final msg = ApiErrorHandler.extractErrorMessage(e);
          throw Exception('Could not mark absent for $dayStr: $msg');
        }
      }
      return lastMessage;
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}
