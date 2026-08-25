import 'package:wowcare/core/util/api_error_handler.dart';
import '../repositories/attendance_repository.dart';

class MarkStudentsAbsentUseCase {
  MarkStudentsAbsentUseCase(this._repository);

  final AttendanceRepository _repository;

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Marks students absent for every calendar day in [absenceFromDate]–[absenceToDate].
  /// The backend creates exactly one record per POST call, so this iterates the
  /// range and posts once per day.
  Future<String> call({
    required String staffCode,
    required List<String> studentCodes,
    required String absenceFromDate,
    required String absenceToDate,
    required String absenceReason,
    required Map<String, String> absenceNotes,
    required String classroomCode,
    required Map<String, bool> isExpectedTodayByStudentCode,
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
          lastMessage = await _repository.markStudentsAbsent(
            staffCode: staffCode,
            studentCodes: studentCodes,
            absenceFromDate: dayStr,
            absenceToDate: dayStr,
            absenceReason: absenceReason,
            absenceNotes: absenceNotes,
            classroomCode: classroomCode,
            isExpectedTodayByStudentCode: isExpectedTodayByStudentCode,
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
