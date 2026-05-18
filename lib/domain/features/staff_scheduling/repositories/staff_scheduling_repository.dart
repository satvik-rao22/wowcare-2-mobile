import '../entities/schedule_entry.dart';
import '../entities/staff_shift.dart';

abstract class StaffSchedulingRepository {
  Future<void> addSchedule(Map<String, dynamic> data);

  Future<void> editSchedule(String id, Map<String, dynamic> data);

  Future<List<StaffShiftEntity>> getStaffShifts({
    required String schoolCode,
    required String organizationCode,
    String? classroomCode,
    required String dateFrom,
    required String dateTo,
    String? shiftStatus,
    int page = 0,
    int size = 50,
  });

  Future<List<Map<String, dynamic>>> getAllClassrooms(String schoolCode);

  Future<List<ScheduleEntryEntity>> getClassroomSchedules();
}
