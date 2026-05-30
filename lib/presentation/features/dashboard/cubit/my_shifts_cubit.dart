import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/scheduling/entities/staff_shift.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shifts_usecase.dart';

part 'my_shifts_state.dart';

class MyShiftsCubit extends Cubit<MyShiftsState> {
  MyShiftsCubit({
    required GetStaffShiftsUseCase getStaffShiftsUseCase,
    required StorageService storageService,
  }) : _getShifts = getStaffShiftsUseCase,
       _storage = storageService,
       super(const MyShiftsState());

  final GetStaffShiftsUseCase _getShifts;
  final StorageService _storage;

  bool _isFetching = false;

  Future<void> load({bool forceRefresh = false}) async {
    if (_isFetching) return;
    if (!forceRefresh && state.isLoaded) return;
    _isFetching = true;

    emit(state.copyWith(status: _Status.loading, clearError: true));

    try {
      final staffCode = (await _storage.getString(StorageKeys.staffCode) ?? '')
          .trim();
      final schoolCode =
          (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();
      final organizationCode =
          (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();

      if (staffCode.isEmpty || schoolCode.isEmpty || organizationCode.isEmpty) {
        emit(
          state.copyWith(
            status: _Status.error,
            errorMessage: 'Missing staff/school context.',
          ),
        );
        return;
      }

      final now = DateTime.now();
      final startOfWeek = _startOfWeek(now);
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final shifts = await _getShifts(
        staffCode: staffCode,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        dateFrom: startOfWeek,
        dateTo: endOfWeek,
      );

      final today = DateTime(now.year, now.month, now.day);
      final todays = shifts
          .where((s) => _sameDay(s.shiftDate, today))
          .toList(growable: false);

      final totals = _extractTotals(shifts);

      final displayName =
          (await _storage.getString(StorageKeys.displayName) ?? '').trim();
      final designation =
          (await _storage.getString(StorageKeys.staffDesignation) ?? '').trim();

      // Pick a classroom label for the profile row:
      // 1) today's first shift classroomName/code
      // 2) any shift classroomName/code
      final classroomLabel = _classroomLabelFor(
        todays.isNotEmpty ? todays : shifts,
      );

      emit(
        state.copyWith(
          status: shifts.isEmpty ? _Status.empty : _Status.loaded,
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
        ),
      );
    } catch (e) {
      final message = ApiErrorHandler.extractErrorMessage(e);
      AppLogger.d('[MyShiftsCubit] load failed: $message');
      emit(state.copyWith(status: _Status.error, errorMessage: message));
    } finally {
      _isFetching = false;
    }
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
    final maxUnscheduled = shifts.fold<int>(
      0,
      (p, s) => s.unscheduledHours > p ? s.unscheduledHours : p,
    );
    return (
      availableHours: maxAvailable,
      scheduledHours: maxScheduled,
      unscheduledHours: maxUnscheduled,
    );
  }

  String _classroomLabelFor(List<StaffShift> shifts) {
    if (shifts.isEmpty) return '';
    final first = shifts.first;
    final name = first.classroomName.trim();
    if (name.isNotEmpty) return name;
    return first.classroomCode.trim();
  }

  /// Formats a shift block time for the existing card widgets
  /// (`hh:mm:ss a`, e.g. "11:09:00 AM").
  static String formatBlockTime(TimeOfDay time) {
    final dt = DateTime(2000, 1, 1, time.hour, time.minute);
    return DateFormat('hh:mm:ss a').format(dt);
  }
}
