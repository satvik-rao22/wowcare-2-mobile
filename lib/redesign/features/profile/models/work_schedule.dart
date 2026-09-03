import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// The weekdays a schedule can name, in the order the day chips draw them.
enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

/// One shift or break on one day, mirroring `StaffProfileWorkSchedule` and
/// `StaffProfileBreakSchedule`: a day and a formatted start and end.
@immutable
class ScheduleEntry extends Equatable {
  const ScheduleEntry({
    required this.day,
    required this.start,
    required this.end,
  });

  final Weekday day;

  /// "7:00 AM", as the profile shows it.
  final String start;
  final String end;

  @override
  List<Object?> get props => <Object?>[day, start, end];
}

/// A staff member's weekly hours: the shifts and the breaks.
@immutable
class WorkSchedule extends Equatable {
  const WorkSchedule({
    this.shifts = const <ScheduleEntry>[],
    this.breaks = const <ScheduleEntry>[],
  });

  final List<ScheduleEntry> shifts;
  final List<ScheduleEntry> breaks;

  bool get isEmpty => shifts.isEmpty;

  /// The days with a shift, for the day chips.
  Set<Weekday> get workingDays => shifts.map((s) => s.day).toSet();

  /// The weekdays the chips show: Monday to Friday, plus any weekend day
  /// that carries a shift.
  List<Weekday> get displayDays => <Weekday>[
    for (final d in Weekday.values)
      if (d.index < Weekday.saturday.index || workingDays.contains(d)) d,
  ];

  /// The first shift, whose hours the card summarises.
  ScheduleEntry? get primaryShift => shifts.isEmpty ? null : shifts.first;

  ScheduleEntry? get primaryBreak => breaks.isEmpty ? null : breaks.first;

  @override
  List<Object?> get props => <Object?>[shifts, breaks];
}
