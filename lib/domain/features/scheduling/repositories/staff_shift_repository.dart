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
    String? classroomCode,
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

  /// Returns dates the staff is marked absent within [from]..[to] (inclusive).
  /// Backed by `GET /api/v1/staff-attendance/profile/absent/toggle` so the
  /// add-shift flow can block / strip absent days before creation.
  Future<List<DateTime>> getStaffAbsentDatesInRange({
    required String staffCode,
    required DateTime from,
    required DateTime to,
  });

  /// `POST /api/v1/staff-shifts/absent-days` — deletes shifts the just-created
  /// recurring series produced on the supplied absent dates. Returns the
  /// number of shifts the backend deleted.
  Future<int> markStaffShiftAbsentDays({
    required String staffCode,
    required String schoolCode,
    required List<DateTime> absentDates,
  });

  /// `PUT /api/v1/staff-shifts/{shiftCode}` — update one shift occurrence.
  Future<StaffShift> updateStaffShift(StaffShiftUpdateRequest request);

  /// `PUT /api/v1/staff-shifts/series/{seriesCode}` — update every occurrence
  /// of a recurring series. Returns the same create-result envelope.
  Future<StaffShiftCreateResult> updateStaffShiftSeries(
    StaffShiftSeriesUpdateRequest request,
  );

  /// `DELETE /api/v1/staff-shifts/{shiftCode}` — remove one shift occurrence.
  Future<void> deleteStaffShift({
    required String shiftCode,
    String? staffCode,
  });

  /// `DELETE /api/v1/staff-shifts/series/{seriesCode}` — remove every shift
  /// in a recurring series.
  Future<void> deleteStaffShiftSeries({
    required String seriesCode,
    String? staffCode,
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
