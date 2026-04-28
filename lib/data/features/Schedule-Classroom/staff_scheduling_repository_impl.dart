import 'package:flutter/material.dart';
import '../../../domain/features/staff_scheduling/entities/schedule_entry.dart';
import '../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import 'staff_scheduling_remote_datasource.dart';
import '../../../core/cache/cache_service.dart';
import 'models/staff_shift_collection.dart';

class StaffSchedulingRepositoryImpl implements StaffSchedulingRepository {
  final StaffSchedulingRemoteDataSource _remoteDataSource;
  final CacheService _cacheService;

  StaffSchedulingRepositoryImpl(this._remoteDataSource, this._cacheService);

  @override
  Future<List<ScheduleEntryEntity>> getClassroomSchedules() async {
    // Simulating API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      ScheduleEntryEntity(
        name: 'Ana Biwalkar',
        avatarUrl: 'https://i.pravatar.cc/150?img=44',
        scheduledHours: '45',
        actualHours: '55',
        slotColors: [
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFF5978F7),
        ],
      ),
      ScheduleEntryEntity(
        name: 'Ana Biwalkar',
        avatarUrl: 'https://i.pravatar.cc/150?img=44',
        scheduledHours: '45',
        actualHours: '55',
        slotColors: [
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFF5978F7),
        ],
      ),

      ScheduleEntryEntity(
        name: 'Ana Biwalkar',
        avatarUrl: 'https://i.pravatar.cc/150?img=44',
        scheduledHours: '45',
        actualHours: '55',
        slotColors: [
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFF5978F7),
        ],
      ),
      ScheduleEntryEntity(
        name: 'Ana Biwalkar',
        avatarUrl: 'https://i.pravatar.cc/150?img=44',
        scheduledHours: '45',
        actualHours: '55',
        slotColors: [
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFF5978F7),
        ],
      ),
      ScheduleEntryEntity(
        name: 'Ana Biwalkar',
        avatarUrl: 'https://i.pravatar.cc/150?img=44',
        scheduledHours: '45',
        actualHours: '55',
        slotColors: [
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFF5978F7),
        ],
      ),
      ScheduleEntryEntity(
        name: 'Ana Biwalkar',
        avatarUrl: 'https://i.pravatar.cc/150?img=44',
        scheduledHours: '45',
        actualHours: '55',
        slotColors: [
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFACF3AA),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFFF38D8D),
          const Color(0xFF5978F7),
        ],
      ),
    ];
  }

  @override
  Future<void> addSchedule(Map<String, dynamic> data) async {
    final responseData = await _remoteDataSource.addSchedule(data);
    if (responseData != null) {
      final createdShiftCodes = responseData['createdShiftCodes'] as List<dynamic>?;
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
    return await _remoteDataSource.editSchedule(id, data);
  }

  @override
  Future<List<StaffShiftEntity>> getStaffShifts({
    required String classroomCode,
    required String dateFrom,
    required String dateTo,
    String shiftStatus = 'PUBLISHED',
  }) async {
    try {
      final remoteShifts = await _remoteDataSource.getStaffShifts(
        classroomCode: classroomCode,
        dateFrom: dateFrom,
        dateTo: dateTo,
        shiftStatus: shiftStatus,
      );

      final shifts = remoteShifts.map((map) {
        return StaffShiftCollection.fromMap(map);
      }).toList();

      // Cache shifts
      await _cacheService.putAll(shifts);

      return shifts.map((s) => s.toEntity()).toList();
    } catch (e) {
      // Fallback to cache on error
      final cachedShifts = await _cacheService.getAll<StaffShiftCollection>();
      return cachedShifts
          .where((s) =>
              s.classroomCode == classroomCode &&
              s.shiftDate.compareTo(dateFrom) >= 0 &&
              s.shiftDate.compareTo(dateTo) <= 0)
          .map((s) => s.toEntity())
          .toList();
    }
  }
}
