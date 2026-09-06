import 'package:wowcare/core/util/logger_service.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/scheduling/repositories/staff_shift_repository.dart';
import '../repositories/attendance_repository.dart';

class MarkStaffAbsentUseCase {
  MarkStaffAbsentUseCase(
    this._repository,
    this._shiftRepository,
    this._storageService,
  );

  final AttendanceRepository _repository;
  final StaffShiftRepository _shiftRepository;
  final StorageService _storageService;

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Marks staff absent for every calendar day in [absenceFromDate]–[absenceToDate].
  /// The backend creates exactly one record per POST call, so this iterates the
  /// range and posts once per day. Shifts are stripped for all absent days.
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
      final markedDays = <DateTime>[];
      for (; !day.isAfter(endDay); day = day.add(const Duration(days: 1))) {
        final dayStr = _ymd(day);
        try {
          // Fresh key per day — see MarkStudentsAbsentUseCase for why a
          // shared key across the range would be wrong here.
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
            idempotencyKey: IdempotencyKey.generate(),
          );
          markedDays.add(day);
        } catch (e) {
          // Strip shifts for any partial successes before bailing so we don't
          // leave a half-marked staff with conflicting shifts.
          await _stripShiftsOnAbsentDays(staffCodes, markedDays);
          final msg = ApiErrorHandler.extractErrorMessage(e);
          throw Exception('Could not mark absent for $dayStr: $msg');
        }
      }
      // Delete existing shifts on all newly-marked absent days.
      await _stripShiftsOnAbsentDays(staffCodes, markedDays);
      return lastMessage;
    } catch (e) {
      throw ApiErrorHandler.extractErrorMessage(e);
    }
  }

  /// Best-effort `POST /api/v1/staff-shifts/absent-days` per affected staff.
  /// Failures here are surfaced via AppLogger (debug-only) but never bubble up — the
  /// mark-absent records have already been written.
  Future<void> _stripShiftsOnAbsentDays(
    List<String> staffCodes,
    List<DateTime> absentDays,
  ) async {
    if (staffCodes.isEmpty || absentDays.isEmpty) return;
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    if (schoolCode.isEmpty) return;
    for (final code in staffCodes) {
      if (code.trim().isEmpty) continue;
      try {
        await _shiftRepository.markStaffShiftAbsentDays(
          staffCode: code,
          schoolCode: schoolCode,
          absentDates: absentDays,
        );
      } catch (e) {
        AppLogger.d('markStaffShiftAbsentDays failed for $code: $e');
      }
    }
  }
}

