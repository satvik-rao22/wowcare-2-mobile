import '../../../domain/features/staff_scheduling/entities/schedule_entry.dart';
import '../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import 'models/staff_shift_collection.dart';
import 'staff_scheduling_remote_datasource.dart';

class StaffSchedulingRepositoryImpl implements StaffSchedulingRepository {
  final StaffSchedulingRemoteDataSource _remoteDataSource;

  StaffSchedulingRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> addSchedule(Map<String, dynamic> data) async {
    // Scheduling no longer uses local Isar/Cache storage.
    await _remoteDataSource.addSchedule(data);
  }

  @override
  Future<void> editSchedule(String id, Map<String, dynamic> data) async {
    await _remoteDataSource.editSchedule(id, data);
  }

  @override
  Future<StaffShiftEntity?> getShiftByCode(String shiftCode) async {
    final map = await _remoteDataSource.getShiftByCode(shiftCode);
    if (map == null) return null;
    return StaffShiftCollection.fromMap(map).toEntity();
  }

  @override
  Future<List<StaffShiftEntity>> getStaffShifts({
    required String schoolCode,
    required String organizationCode,
    String? classroomCode,
    required String dateFrom,
    required String dateTo,
    String? shiftStatus,
    int page = 0,
    int size = 50,
  }) async {
    final remoteShifts = await _remoteDataSource.getStaffShifts(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      classroomCode: classroomCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
      // shiftStatus: shiftStatus ?? 'PUBLISHED',
      page: page,
      size: size,
    );

    return remoteShifts
        .map((map) => StaffShiftCollection.fromMap(map).toEntity())
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllClassrooms(String schoolCode) async {
    return await _remoteDataSource.getAllClassrooms(schoolCode);
  }

  @override
  Future<List<ScheduleEntryEntity>> getClassroomSchedules() async {
    return [];
  }
}
