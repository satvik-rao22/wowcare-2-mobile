import '../../../core/cache/cache_service.dart';
import '../../../domain/features/staff_scheduling/entities/schedule_entry.dart';
import '../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import 'models/staff_shift_collection.dart';
import 'staff_scheduling_remote_datasource.dart';

class StaffSchedulingRepositoryImpl implements StaffSchedulingRepository {
  final StaffSchedulingRemoteDataSource _remoteDataSource;
  final CacheService _cacheService;

  StaffSchedulingRepositoryImpl(this._remoteDataSource, this._cacheService);

  @override
  Future<void> addSchedule(Map<String, dynamic> data) async {
    final responseData = await _remoteDataSource.addSchedule(data);

    if (responseData != null) {
      final createdShiftCodes =
          responseData['createdShiftCodes'] as List<dynamic>?;

      if (createdShiftCodes != null && createdShiftCodes.isNotEmpty) {
        final shifts = createdShiftCodes.map((code) {
          return StaffShiftCollection.fromMap(data, code: code as String);
        }).toList();

        await _cacheService.putAll(shifts);
      }
    }
  }

  @override
  Future<void> editSchedule(String id, Map<String, dynamic> data) async {
    await _remoteDataSource.editSchedule(id, data);
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
    try {
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

      final shifts = remoteShifts.map((map) {
        return StaffShiftCollection.fromMap(map);
      }).toList();

      await _cacheService.putAll(shifts);

      return shifts.map((s) => s.toEntity()).toList();
    } catch (e) {
      final cachedShifts = await _cacheService.getAll<StaffShiftCollection>();

      return cachedShifts
          .where(
            (s) =>
                (classroomCode == null || s.classroomCode == classroomCode) &&
                s.shiftDate.compareTo(dateFrom) >= 0 &&
                s.shiftDate.compareTo(dateTo) <= 0,
          )
          .map((s) => s.toEntity())
          .toList();
    }
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
