import '../entities/schedule_entry.dart';

abstract class StaffSchedulingRepository {
  Future<List<ScheduleEntryEntity>> getClassroomSchedules();
  Future<void> addSchedule(Map<String, dynamic> data);
  Future<void> editSchedule(String id, Map<String, dynamic> data);
}
