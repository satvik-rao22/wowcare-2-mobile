import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;

import '../../../../domain/features/staff/usecases/get_school_regular_schedules_usecase.dart';

part 'student_schedule_state.dart';

/// Owns the Add-Student Step-3 weekly-schedule editor: the per-day times, the
/// "copy to all days" flag, the school's working-hours bounds, and ALL the
/// schedule manipulation + working-hours validation. The screen only renders
/// [state] and shows the error strings these methods return.
class StudentScheduleCubit extends Cubit<StudentScheduleState> {
  StudentScheduleCubit({
    required GetSchoolRegularSchedulesUseCase getSchoolRegularSchedulesUseCase,
  })  : _getSchoolRegularSchedulesUseCase = getSchoolRegularSchedulesUseCase,
        super(const StudentScheduleState.initial());

  final GetSchoolRegularSchedulesUseCase _getSchoolRegularSchedulesUseCase;

  static const TimeOfDay _fallbackStart = TimeOfDay(hour: 7, minute: 0);
  static const TimeOfDay _fallbackEnd = TimeOfDay(hour: 18, minute: 0);

  static const Map<String, String> _dayNameByApiKey = <String, String>{
    'MONDAY': 'Monday',
    'TUESDAY': 'Tuesday',
    'WEDNESDAY': 'Wednesday',
    'THURSDAY': 'Thursday',
    'FRIDAY': 'Friday',
    'SATURDAY': 'Saturday',
    'SUNDAY': 'Sunday',
  };

  static const List<String> _apiDayOrder = <String>[
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  /// Display names of the days the school is open (derived from the loaded
  /// working-hours map; empty until [loadSchoolSchedules] runs).
  List<String> get workingDays => _apiDayOrder
      .where(state.schoolMinutesByDay.containsKey)
      .map((k) => _dayNameByApiKey[k]!)
      .toList(growable: false);

  /// Seed from the caller's initial schedule (deep-copied) or leave empty; the
  /// default per-day times are filled after [loadSchoolSchedules] resolves the
  /// working days.
  void initialize(Map<String, Map<String, TimeOfDay>>? initialSchedule) {
    final hasInitial = initialSchedule != null;
    final schedule = <String, Map<String, TimeOfDay>>{};
    if (initialSchedule != null) {
      initialSchedule.forEach((day, times) {
        schedule[day] = {
          for (final e in times.entries)
            e.key: TimeOfDay(hour: e.value.hour, minute: e.value.minute),
        };
      });
    }
    emit(state.copyWith(
      schedule: schedule,
      hasInitialSchedule: hasInitial,
    ));
  }

  /// Fetch the school's regular schedules, keep only working days, drop any
  /// scheduled entries on now-closed days, and (when there was no initial
  /// schedule) fill default per-day times. Returns the days removed for the
  /// caller to surface ("X removed — school closed that day").
  Future<List<String>> loadSchoolSchedules(String schoolCode) async {
    try {
      final days = await _getSchoolRegularSchedulesUseCase(
        schoolCode: schoolCode,
      );
      final map = <String, (int, int)>{};
      for (final d in days) {
        final isOff = (d.status != null && !d.isActive) || !d.isRegular;
        if (isOff) continue;
        map[d.dayOfWeek] = (
          _timeStringToMinutes(d.startTime),
          _timeStringToMinutes(d.endTime),
        );
      }
      if (isClosed) return const [];

      final removedOffDays = <String>[];
      final prunedSchedule = <String, Map<String, TimeOfDay>>{};
      state.schedule.forEach((day, times) {
        if (map.containsKey(day.toUpperCase())) {
          prunedSchedule[day] = times;
        } else {
          removedOffDays.add(day);
        }
      });

      emit(state.copyWith(
        schoolMinutesByDay: map,
        schedule: prunedSchedule,
      ));
      if (!state.hasInitialSchedule) {
        _initializeDefaultSchedule(overwriteExisting: true);
      }
      return removedOffDays;
    } catch (_) {
      // Keep fallback hours if the API fails.
      return const [];
    }
  }

  /// Apply a picked time. Returns an error string (for a snackbar) or null on
  /// success. Honors "copy to all days" when both ends are set.
  String? applyPickedTime(String day, String timeType, TimeOfDay picked) {
    final nextDayTimes = Map<String, TimeOfDay>.from(state.schedule[day] ?? {});
    nextDayTimes[timeType] = picked;

    final dayErr = validateDaySchedule(day, nextDayTimes);
    if (dayErr != null) return dayErr;

    if (state.copyToAllDays &&
        nextDayTimes['start'] != null &&
        nextDayTimes['end'] != null) {
      final start = nextDayTimes['start']!;
      final end = nextDayTimes['end']!;
      final merged = <String, Map<String, TimeOfDay>>{};
      for (final d in workingDays) {
        merged[d] = {
          'start': TimeOfDay(hour: start.hour, minute: start.minute),
          'end': TimeOfDay(hour: end.hour, minute: end.minute),
        };
      }
      for (final d in workingDays) {
        final err = validateDaySchedule(d, merged[d]);
        if (err != null) return err;
      }
      emit(state.copyWith(schedule: merged));
      return null;
    }

    emit(state.copyWith(
      schedule: {...state.schedule, day: nextDayTimes},
    ));
    return null;
  }

  void removeDay(String day) {
    final next = Map<String, Map<String, TimeOfDay>>.from(state.schedule)
      ..remove(day);
    emit(state.copyWith(schedule: next));
  }

  void enableDay(String day) {
    emit(state.copyWith(
      schedule: {
        ...state.schedule,
        day: {
          'start': defaultStartForDay(day),
          'end': defaultEndForDay(day),
        },
      },
    ));
  }

  /// Toggle "copy to all days"; when turned on, copy the first day that already
  /// has both times to every working day.
  void setCopyToAllDays(bool value) {
    emit(state.copyWith(copyToAllDays: value));
    if (value) _copyFromFirstAvailableDay();
  }

  /// Validate every working day's current times (used to gate "copy to all
  /// days"). Returns the first error string or null.
  String? validateAllScheduledDays() {
    for (final day in workingDays) {
      final err = validateDaySchedule(day, state.schedule[day]);
      if (err != null) return err;
    }
    return null;
  }

  /// Validate the whole schedule for submit. Returns an error string or null.
  String? validateForSubmit() {
    if (state.schedule.isEmpty) {
      return 'Please add at least one day to the schedule';
    }
    for (final entry in state.schedule.entries) {
      final day = entry.key;
      final times = entry.value;
      if (!state.schoolMinutesByDay.containsKey(day.toUpperCase())) {
        return '$day is a school off day and cannot be scheduled.';
      }
      if (times['start'] == null || times['end'] == null) {
        return 'Please set both start and end times for $day';
      }
      if (!_isAfter(times['end']!, times['start']!)) {
        return 'End time must be after start time for $day';
      }
      final err = validateDaySchedule(day, times);
      if (err != null) return err;
    }
    return null;
  }

  // --- internal helpers (moved verbatim from the view) ---

  void _initializeDefaultSchedule({bool overwriteExisting = false}) {
    final next = Map<String, Map<String, TimeOfDay>>.from(state.schedule);
    for (final day in workingDays) {
      if (!overwriteExisting && next.containsKey(day)) continue;
      next[day] = {
        'start': defaultStartForDay(day),
        'end': defaultEndForDay(day),
      };
    }
    emit(state.copyWith(schedule: next));
  }

  void _copyFromFirstAvailableDay() {
    for (final day in workingDays) {
      final s = state.schedule[day];
      if (s != null && s['start'] != null && s['end'] != null) {
        _copyScheduleFromDay(day);
        break;
      }
    }
  }

  void _copyScheduleFromDay(String sourceDay) {
    final source = state.schedule[sourceDay];
    final start = source?['start'];
    final end = source?['end'];
    if (start == null || end == null) return;
    final next = Map<String, Map<String, TimeOfDay>>.from(state.schedule);
    for (final day in workingDays) {
      if (day == sourceDay) continue;
      next[day] = {
        'start': TimeOfDay(hour: start.hour, minute: start.minute),
        'end': TimeOfDay(hour: end.hour, minute: end.minute),
      };
    }
    emit(state.copyWith(schedule: next));
  }

  (int, int)? _boundsForDay(String day) =>
      state.schoolMinutesByDay[day.toUpperCase()];

  TimeOfDay defaultStartForDay(String day) {
    final bounds = _boundsForDay(day);
    return bounds != null ? _minutesToTimeOfDay(bounds.$1) : _fallbackStart;
  }

  TimeOfDay defaultEndForDay(String day) {
    final bounds = _boundsForDay(day);
    return bounds != null ? _minutesToTimeOfDay(bounds.$2) : _fallbackEnd;
  }

  bool _isTimeInWorkingHours(TimeOfDay time, String day) {
    final timeMinutes = time.hour * 60 + time.minute;
    final bounds = _boundsForDay(day);
    final startMinutes =
        bounds?.$1 ?? (_fallbackStart.hour * 60 + _fallbackStart.minute);
    final endMinutes =
        bounds?.$2 ?? (_fallbackEnd.hour * 60 + _fallbackEnd.minute);
    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  String? validateDaySchedule(String day, Map<String, TimeOfDay>? times) {
    if (times == null) return null;
    final start = times['start'];
    final end = times['end'];
    final bounds = _boundsForDay(day);
    final allowedStart =
        bounds != null ? _minutesToTimeOfDay(bounds.$1) : _fallbackStart;
    final allowedEnd =
        bounds != null ? _minutesToTimeOfDay(bounds.$2) : _fallbackEnd;

    if (start != null && !_isTimeInWorkingHours(start, day)) {
      return 'On $day, start time must be within school working hours '
          '(${formatTime(allowedStart)} - ${formatTime(allowedEnd)}).';
    }
    if (end != null && !_isTimeInWorkingHours(end, day)) {
      return 'On $day, end time must be within school working hours '
          '(${formatTime(allowedStart)} - ${formatTime(allowedEnd)}).';
    }
    if (bounds != null) {
      if (start != null) {
        final sm = start.hour * 60 + start.minute;
        if (sm < bounds.$1 || sm > bounds.$2) {
          return 'On $day, start time must be within school hours '
              '(${formatTime(allowedStart)} - ${formatTime(allowedEnd)}).';
        }
      }
      if (end != null) {
        final em = end.hour * 60 + end.minute;
        if (em < bounds.$1 || em > bounds.$2) {
          return 'On $day, end time must be within school hours '
              '(${formatTime(allowedStart)} - ${formatTime(allowedEnd)}).';
        }
      }
    }
    if (start != null && end != null && !_isAfter(end, start)) {
      return 'On $day, end time must be after start time.';
    }
    return null;
  }

  bool _isAfter(TimeOfDay a, TimeOfDay b) =>
      (a.hour * 60 + a.minute) > (b.hour * 60 + b.minute);

  static int _timeStringToMinutes(String s) {
    final p = s.trim().split(':');
    if (p.length < 2) return 0;
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    return (h * 60 + m).clamp(0, 24 * 60);
  }

  static TimeOfDay _minutesToTimeOfDay(int totalMinutes) {
    final clamped = totalMinutes.clamp(0, 24 * 60);
    return TimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
  }

  /// 12-hour "h:mm AM/PM" (also used by the view for display).
  static String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
