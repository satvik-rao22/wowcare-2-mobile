import '../entities/staff_shift.dart';

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
