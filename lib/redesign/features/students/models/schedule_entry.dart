import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// One weekday of a student's regular schedule (5d step three).
///
/// Mirrors `StudentRegularScheduleEntry`: a day of the week and its start and
/// end, held as minutes past midnight so a time picker writes one number.
@immutable
class ScheduleEntry extends Equatable {
  const ScheduleEntry({
    required this.dayIndex,
    this.isOpen = true,
    this.startMinutes = _defaultStart,
    this.endMinutes = _defaultEnd,
  });

  /// 9:00, the hour the design's own schedule card opens on.
  static const int _defaultStart = 9 * 60;
  static const int _defaultEnd = 16 * 60;

  /// 0 is Monday, 4 is Friday.
  final int dayIndex;

  /// A closed day carries no times and reads "Closed".
  final bool isOpen;

  final int startMinutes;
  final int endMinutes;

  String get dayLabel => StudentsStrings.weekdays[dayIndex];

  /// The full week, open Monday to Friday at the default hours.
  static List<ScheduleEntry> week() => <ScheduleEntry>[
    for (var i = 0; i < StudentsStrings.weekdays.length; i++)
      ScheduleEntry(dayIndex: i),
  ];

  ScheduleEntry copyWith({bool? isOpen, int? startMinutes, int? endMinutes}) =>
      ScheduleEntry(
        dayIndex: dayIndex,
        isOpen: isOpen ?? this.isOpen,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
      );

  @override
  List<Object?> get props => [dayIndex, isOpen, startMinutes, endMinutes];
}
