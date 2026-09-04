import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One day of a staff member's working week: when they start, when they
/// finish, and when the lunch break falls (6c Schedule, 6d step three).
///
/// Mirrors `StaffProfileWorkSchedule` + `StaffProfileBreakSchedule` from
/// `lib/domain/features/staff/entities/staff_profile.dart`, which the app
/// already reads off `/api/v1/staff-schedules`. The two arrive as separate
/// lists keyed by day; they are one row here because that is how both the
/// week card and the shift editor draw them.
///
/// Times are minutes after midnight so a comparison is arithmetic rather than
/// string work. A day with no [startMinutes] is a day off.
@immutable
class StaffShift extends Equatable {
  const StaffShift({
    required this.weekday,
    this.date,
    this.startMinutes,
    this.endMinutes,
    this.breakStartMinutes,
    this.breakEndMinutes,
    this.classroom = '',
  });

  /// `DateTime.monday` through `DateTime.sunday`.
  final int weekday;

  /// The calendar day this shift falls on, when the week card is showing a
  /// dated week rather than a repeating pattern.
  final DateTime? date;

  final int? startMinutes;
  final int? endMinutes;
  final int? breakStartMinutes;
  final int? breakEndMinutes;

  /// Where the shift is worked. Blank when it is the staff member's usual
  /// classroom and the row does not need to say so.
  final String classroom;

  bool get isDayOff => startMinutes == null || endMinutes == null;

  bool get hasBreak => breakStartMinutes != null && breakEndMinutes != null;

  /// Hours on the clock, breaks taken out. Zero on a day off.
  int get workedMinutes {
    if (isDayOff) return 0;
    final worked = endMinutes! - startMinutes!;
    final rest = hasBreak ? breakEndMinutes! - breakStartMinutes! : 0;
    return worked - rest < 0 ? 0 : worked - rest;
  }

  /// The break falls inside the shift, which is what 6d refuses to save.
  bool get isBreakInsideShift {
    if (!hasBreak || isDayOff) return true;
    return breakStartMinutes! >= startMinutes! &&
        breakEndMinutes! <= endMinutes!;
  }

  bool get isOrderValid => isDayOff || endMinutes! > startMinutes!;

  StaffShift copyWith({
    DateTime? date,
    int? startMinutes,
    int? endMinutes,
    int? breakStartMinutes,
    int? breakEndMinutes,
    String? classroom,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearBreak = false,
  }) => StaffShift(
    weekday: weekday,
    date: date ?? this.date,
    startMinutes: clearStart ? null : startMinutes ?? this.startMinutes,
    endMinutes: clearEnd ? null : endMinutes ?? this.endMinutes,
    breakStartMinutes: clearBreak
        ? null
        : breakStartMinutes ?? this.breakStartMinutes,
    breakEndMinutes: clearBreak
        ? null
        : breakEndMinutes ?? this.breakEndMinutes,
    classroom: classroom ?? this.classroom,
  );

  /// The same times, moved onto [weekday]. What "Copy to all days" does.
  StaffShift copyOnto(int weekday) => StaffShift(
    weekday: weekday,
    date: date,
    startMinutes: startMinutes,
    endMinutes: endMinutes,
    breakStartMinutes: breakStartMinutes,
    breakEndMinutes: breakEndMinutes,
    classroom: classroom,
  );

  @override
  List<Object?> get props => [
    weekday,
    date,
    startMinutes,
    endMinutes,
    breakStartMinutes,
    breakEndMinutes,
    classroom,
  ];
}
