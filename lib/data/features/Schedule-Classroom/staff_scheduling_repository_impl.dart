import 'package:flutter/material.dart';
import '../../../domain/features/staff_scheduling/entities/schedule_entry.dart';
import '../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';

class StaffSchedulingRepositoryImpl implements StaffSchedulingRepository {
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
    // Simulating API delay
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  @override
  Future<void> editSchedule(String id, Map<String, dynamic> data) async {
    // Simulating API delay
    await Future.delayed(const Duration(milliseconds: 1000));
  }
}
