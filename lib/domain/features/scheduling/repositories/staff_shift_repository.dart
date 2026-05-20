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
