import '../../staff/entities/staff_shift.dart';

/// Staff Scheduling repository — backed by staff MS (`/api/v1/staff-shifts`, etc.).
abstract class StaffSchedulingRepository {
  Future<StaffShiftDaySummary> getStaffShiftsForDay({
    required String organizationCode,
    required String schoolCode,
    required String staffCode,
    required DateTime date,
    String? classroomCode,
    List<String>? shiftStatus,
  });
}
