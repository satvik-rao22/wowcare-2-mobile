import 'package:flutter/material.dart';

import '../entities/classroom_forecast_block.dart';
import '../entities/staff_shift.dart';
import '../entities/staff_shift_hours_entry.dart';

/// Parameters for `POST .../classroom/forecast`.
class ClassroomForecastQuery {
  const ClassroomForecastQuery({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.classroomCodes,
  });

  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int durationMinutes;
  final List<String> classroomCodes;
}

/// Parameters for `POST .../classroom/forecast/range`.
class ClassroomForecastRangeQuery {
  const ClassroomForecastRangeQuery({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.classroomCodes,
  });

  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int durationMinutes;
  final List<String> classroomCodes;
}

abstract class StaffShiftRepository {
  /// Lists shifts for [staffCode] between [dateFrom] and [dateTo] (inclusive).
  Future<List<StaffShift>> getStaffShifts({
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required DateTime dateFrom,
    required DateTime dateTo,
  });

  /// School-wide shifts for [dateFrom]..[dateTo]. Used by the classroom
  /// scheduling table where shifts span all staff in the school.
  Future<List<StaffShift>> getSchoolStaffShifts({
    required String schoolCode,
    required String organizationCode,
    required DateTime dateFrom,
    required DateTime dateTo,
  });

  /// `GET /api/v1/staff-shifts/{shiftCode}` — full detail for one shift.
  Future<StaffShift> getStaffShiftByCode(String shiftCode);

  /// Creates one or many shifts (POST `/api/v1/staff-shifts`).
  /// Returns the result envelope (created/skipped/overridden counts + dates).
  Future<StaffShiftCreateResult> createStaffShift(
    StaffShiftCreateRequest request,
  );

  Future<List<ClassroomForecastBlock>> getClassroomForecast({
    required String schoolCode,
    required String organizationCode,
    required ClassroomForecastQuery query,
  });

  Future<List<ClassroomForecastBlock>> getClassroomForecastRange({
    required String schoolCode,
    required String organizationCode,
    required ClassroomForecastRangeQuery query,
  });

  /// `POST /api/v1/staff-shifts/hours/range` — per-staff day hour totals.
  Future<List<StaffShiftHoursEntry>> getStaffShiftHoursRange({
    required String schoolCode,
    required String organizationCode,
    required DateTime startDate,
    required DateTime endDate,
    List<String> staffCodes = const <String>[],
  });
}

/// Optional cache-aware contract — same pattern as `StaffRepositoryWithCache`.
abstract class StaffShiftRepositoryWithCache {
  Future<List<StaffShift>?> loadCachedStaffShifts({
    required String staffCode,
    required String schoolCode,
    required DateTime dateFrom,
    required DateTime dateTo,
  });

  Future<void> invalidateCachedStaffShifts({
    required String staffCode,
    String? schoolCode,
  });
}
