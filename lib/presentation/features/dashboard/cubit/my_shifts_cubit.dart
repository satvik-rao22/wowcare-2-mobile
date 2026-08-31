import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_ratio_monitoring_classrooms_usecase.dart';
import 'package:wowcare/domain/features/classroom/entities/ratio_monitoring_classroom.dart';
import 'package:wowcare/domain/features/scheduling/entities/staff_shift.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shifts_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/scheduling/utils/school_hours_resolver.dart';

part 'my_shifts_state.dart';

class MyShiftsCubit extends Cubit<MyShiftsState> {
  MyShiftsCubit({
    required GetStaffShiftsUseCase getStaffShiftsUseCase,
    required GetRatioMonitoringClassroomsUseCase getClassroomsUseCase,
    required StorageService storageService,
    required StaffRepository staffRepository,
  }) : _getShifts = getStaffShiftsUseCase,
       _getClassrooms = getClassroomsUseCase,
       _storage = storageService,
       _staffRepository = staffRepository,
       super(const MyShiftsState());

  final GetStaffShiftsUseCase _getShifts;
  final GetRatioMonitoringClassroomsUseCase _getClassrooms;
  final StorageService _storage;
  final StaffRepository _staffRepository;

  bool _isFetching = false;

  Future<void> load({DateTime? date, bool forceRefresh = false}) async {
    final targetDate = date ?? state.selectedDate ?? AppTime.now();
    final normalizedDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    final startOfWeek = _startOfWeek(normalizedDate);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    if (_isFetching) return;
    _isFetching = true;

    emit(state.copyWith(status: _Status.loading, clearError: true));

    try {
      // Fan out all storage reads first so they run concurrently instead of
      // as separate sequential round-trips.
      final staffCodeFuture = _storage.getString(StorageKeys.staffCode);
      final schoolCodeFuture = _storage.getString(StorageKeys.schoolCode);
      final organizationCodeFuture = _storage.getString(
        StorageKeys.organizationCode,
      );
      final displayNameFuture = _storage.getString(StorageKeys.displayName);
      final staffDesignationFuture = _storage.getString(
        StorageKeys.staffDesignation,
      );

      final staffCode = ((await staffCodeFuture) ?? '').trim();
      final schoolCode = ((await schoolCodeFuture) ?? '').trim();
      final organizationCode = ((await organizationCodeFuture) ?? '').trim();

      if (staffCode.isEmpty || schoolCode.isEmpty || organizationCode.isEmpty) {
        emit(
          state.copyWith(
            status: _Status.error,
            errorMessage: 'Missing staff/school context.',
          ),
        );
        return;
      }

      final displayName = ((await displayNameFuture) ?? '').trim();
      String rawDesignation = ((await staffDesignationFuture) ?? '').trim();
      final needsProfileLookup = rawDesignation.isEmpty && staffCode.isNotEmpty;
      // Fired here (not after the main fetch below) so it runs concurrently
      // with shifts/classrooms/school-hours instead of serializing after them.
      final profileFuture = needsProfileLookup
          ? _staffRepository.getStaffProfile(staffCode: staffCode)
          : null;

      // ── Fetch shifts + classroom name map + school hours in parallel ─────
      // getSchoolRegularSchedules used to be fetched sequentially after
      // everything else — now it's part of the same fan-out.
      final results = await Future.wait<dynamic>([
        _getShifts(
          staffCode: staffCode,
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          dateFrom: startOfWeek,
          dateTo: endOfWeek,
        ),
        _getClassrooms(schoolCode: schoolCode).catchError(
          // Non-fatal — classroom names degrade to codes if this fails.
          (_) => <RatioMonitoringClassroom>[],
        ),
        _staffRepository
            .getSchoolRegularSchedules(schoolCode: schoolCode)
            .catchError(
              (_) => <SchoolRegularScheduleDay>[],
            ), // non-fatal — school hours degrade to empty
      ]);

      final shifts = results[0] as List<StaffShift>;

      // Build code → name lookup from the classroom list.
      final classroomList = results[1] as List<dynamic>;
      final classroomNames = <String, String>{
        for (final c in classroomList)
          if (c.code.toString().trim().isNotEmpty)
            c.code.toString().trim(): c.name.toString().trim(),
      };

      final todays = shifts
          .where((s) => _sameDay(s.shiftDate, normalizedDate))
          .toList(growable: false);

      // Calculate totals from today's shifts only (not the entire week)
      final totals = _extractTotals(todays);

      // DEBUG: Log the extracted totals
      AppLogger.d('[MyShiftsCubit] Today has ${todays.length} shifts');
      for (var (i, shift) in todays.indexed) {
        AppLogger.d(
          '[MyShiftsCubit] Shift $i: avail=${shift.availableHours}, sched=${shift.scheduledHours}, unsched=${shift.unscheduledHours}',
        );
      }
      AppLogger.d(
        '[MyShiftsCubit] Extracted Totals: avail=${totals.availableHours}, sched=${totals.scheduledHours}, unsched=${totals.unscheduledHours}',
      );

      if (needsProfileLookup) {
        try {
          final profile = await profileFuture!;
          rawDesignation = profile.designation.trim();
          if (rawDesignation.isNotEmpty) {
            await _storage.saveString(
              StorageKeys.staffDesignation,
              rawDesignation,
            );
          }
        } catch (_) {}
      }
      final designation = _formatDesignation(rawDesignation);

      final classroomLabel = _classroomLabelFor(
        todays.isNotEmpty ? todays : shifts,
        classroomNames: classroomNames,
      );

      // ── Resolve school hours for the selected day ──────────────────────────
      String schoolStartTime = '';
      String schoolEndTime = '';
      try {
        final schoolDays = results[2] as List<dynamic>;
        final resolver = SchoolHoursResolver.fromDays(schoolDays.cast());
        final hoursForDay = resolver.hoursFor(normalizedDate);
        if (hoursForDay != null) {
          schoolStartTime = hoursForDay.startTime;
          schoolEndTime = hoursForDay.endTime;
        }
      } catch (e) {
        // Non-fatal — if API fails, schoolStartTime/schoolEndTime remain empty
        AppLogger.d('[MyShiftsCubit] Failed to load school hours: $e');
      }

      final newState = state.copyWith(
        status: shifts.isEmpty ? _Status.empty : _Status.loaded,
        staffCode: staffCode,
        staffName: displayName,
        designation: designation,
        classroomLabel: classroomLabel,
        shifts: shifts,
        todayShifts: todays,
        availableHours: totals.availableHours,
        scheduledHours: totals.scheduledHours,
        unscheduledHours: totals.unscheduledHours,
        weekFrom: startOfWeek,
        weekTo: endOfWeek,
        selectedDate: normalizedDate,
        classroomNames: classroomNames,
        schoolStartTime: schoolStartTime,
        schoolEndTime: schoolEndTime,
      );

      // DEBUG: Log the state before emitting
      AppLogger.d(
        '[MyShiftsCubit] State to emit: avail=${newState.availableHours}, sched=${newState.scheduledHours}, unsched=${newState.unscheduledHours}',
      );

      emit(newState);
    } catch (e) {
      final message = ApiErrorHandler.extractErrorMessage(e);
      AppLogger.d('[MyShiftsCubit] load failed: $message');
      emit(state.copyWith(status: _Status.error, errorMessage: message));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> changeSelectedDate(DateTime date) async {
    await load(date: date);
  }

  DateTime _startOfWeek(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  ({int availableHours, int scheduledHours, int unscheduledHours})
  _extractTotals(List<StaffShift> shifts) {
    if (shifts.isEmpty)
      return (availableHours: 0, scheduledHours: 0, unscheduledHours: 0);
    // Backend typically repeats these totals on each shift object for the range.
    final maxAvailable = shifts.fold<int>(
      0,
      (p, s) => s.availableHours > p ? s.availableHours : p,
    );
    final maxScheduled = shifts.fold<int>(
      0,
      (p, s) => s.scheduledHours > p ? s.scheduledHours : p,
    );
    // Calculate unscheduled as the difference to ensure consistency
    final maxUnscheduled = (maxAvailable - maxScheduled).clamp(0, 9999);
    return (
      availableHours: maxAvailable,
      scheduledHours: maxScheduled,
      unscheduledHours: maxUnscheduled,
    );
  }

  String _classroomLabelFor(
    List<StaffShift> shifts, {
    Map<String, String> classroomNames = const {},
  }) {
    if (shifts.isEmpty) return '';
    final first = shifts.first;
    final code = first.classroomCode.trim();
    // Prefer the classroom list name, then the API-provided name, then the code.
    final fromList = code.isNotEmpty ? (classroomNames[code] ?? '') : '';
    if (fromList.isNotEmpty) return fromList;
    final name = first.classroomName.trim();
    if (name.isNotEmpty) return name;
    return code;
  }

  /// Converts enum-style designation strings to human-readable title case.
  /// e.g. "ASSOCIATE_TEACHER" → "Associate Teacher", "FULL_TIME" → "Full-Time".
  static String _formatDesignation(String raw) {
    if (raw.isEmpty) return '';
    final upper = raw.trim().toUpperCase();
    if (upper == 'FULL_TIME') return 'Full-Time';
    if (upper == 'PART_TIME') return 'Part-Time';
    return upper
        .split(RegExp(r'[_\s]+'))
        .map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .where((w) => w.isNotEmpty)
        .join(' ');
  }

  /// Formats a shift block time for the existing card widgets
  /// (`hh:mm:ss a`, e.g. "11:09:00 AM").
  static String formatBlockTime(TimeOfDay time) {
    final dt = DateTime(2000, 1, 1, time.hour, time.minute);
    return DateFormat('hh:mm:ss a').format(dt);
  }
}
