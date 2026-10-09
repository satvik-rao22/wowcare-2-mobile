import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/idempotency_key.dart';
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
      final stopwatch = Stopwatch()..start();
      for (; !day.isAfter(endDay); day = day.add(const Duration(days: 1))) {
        final dayStr = _ymd(day);
        try {
          // A fresh key PER DAY — each iteration is a genuinely distinct
          // mutation (a different day's absence record), so a single shared
          // key across the whole range would make the backend dedupe day 2
          // as a "replay" of day 1. Stable across a 401-refresh auto-replay
          // of THIS specific day's request, since that reuses the same
          // RequestOptions/headers.
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
            idempotencyKey: IdempotencyKey.generate(),
          );
        } catch (e) {
          AppEvents.failed(
            AppEvent.attendanceStudentMarkAbsent,
            e,
            count: studentCodes.length,
            durationMs: stopwatch.elapsedMilliseconds,
          );
          final msg = ApiErrorHandler.extractErrorMessage(e);
          throw Exception('Could not mark absent for $dayStr: $msg');
        }
      }
      AppEvents.succeeded(
        AppEvent.attendanceStudentMarkAbsent,
        count: studentCodes.length,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      return lastMessage;
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }
}

