/// =============================
/// DOMAIN LAYER
/// =============================

import '../entities/schedule_entry.dart';
import '../entities/staff_shift.dart';

abstract class StaffSchedulingRepository {
  Future<List<ScheduleEntryEntity>> getClassroomSchedules();

  Future<void> addSchedule(Map<String, dynamic> data);

  Future<void> editSchedule(String id, Map<String, dynamic> data);

  Future<List<StaffShiftEntity>> getStaffShifts({
    String? classroomCode,
    required String dateFrom,
    required String dateTo,
    String? shiftStatus,
  });

  Future<List<Map<String, dynamic>>> getAllClassrooms(String schoolCode);
}
