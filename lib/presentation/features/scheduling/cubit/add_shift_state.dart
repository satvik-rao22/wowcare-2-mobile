part of 'add_shift_cubit.dart';

/// Immutable form + async state for [AddShiftScreen]. Every field that the old
/// `StatefulWidget` tracked via `setState` now lives here; the view is a pure
/// function of this state plus the staff/classroom lists it reads from the
/// surrounding cubits.
class AddShiftState extends Equatable {
  const AddShiftState({
    required this.date,
    this.untilDate,
    this.selectedClassroomCode,
    this.selectedStaffCode,
    this.shiftStart,
    this.shiftEnd,
    this.breakStart,
    this.breakEnd,
    this.repeatOn = false,
    this.selectedDays = const <String>{},
    this.publish = false,
    this.saving = false,
    this.noScheduleForSelectedDate = false,
    this.schoolHoursResolver,
    this.adminClassrooms = const <Classroom>[],
    this.untilDateError,
    this.shiftStartError,
    this.shiftEndError,
    this.breakStartError,
    this.breakEndError,
    this.daysError,
    this.schoolHoursError,
  });

  final DateTime date;
  final DateTime? untilDate;
  final String? selectedClassroomCode;
  final String? selectedStaffCode;

  final TimeOfDay? shiftStart;
  final TimeOfDay? shiftEnd;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;

  final bool repeatOn;
  final Set<String> selectedDays;
  final bool publish;
  final bool saving;

  /// True when the selected staff has no work-schedule entry for the selected
  /// date's weekday. Drives the inline red message below the break row.
  final bool noScheduleForSelectedDate;

  /// School open/close hours per weekday. Drives the hard-rule check that
  /// shift / break times must fall inside school hours. Null while the API is
  /// still in flight.
  final SchoolHoursResolver? schoolHoursResolver;

  /// Classrooms returned by the ADMIN-type lookup. Merged into the Classroom
  /// dropdown when the selected staff has a teacher designation.
  final List<Classroom> adminClassrooms;

  final String? untilDateError;
  final String? shiftStartError;
  final String? shiftEndError;
  final String? breakStartError;
  final String? breakEndError;
  final String? daysError;
  final String? schoolHoursError;

  /// School's open days for the repeat-days grid — strictly the days the
  /// regular-schedule API returned. Empty while the API is still in flight.
  List<String> get availableWeekDays {
    final resolver = schoolHoursResolver;
    if (resolver == null) return const <String>[];
    final result = <String>[];
    for (final name in _weekDaysOrder) {
      final weekday = _weekDayIndex[name];
      if (weekday == null) continue;
      if (_schoolHoursForWeekday(weekday) != null) {
        result.add(name);
      }
    }
    return result;
  }

  bool get isFormValid {
    if (selectedStaffCode == null || selectedStaffCode!.isEmpty) return false;
    if (selectedClassroomCode == null || selectedClassroomCode!.isEmpty) {
      return false;
    }
    if (shiftStart == null || shiftEnd == null) return false;
    if (repeatOn) {
      if (selectedDays.isEmpty) return false;
      if (untilDate == null) return false;
    }
    return true;
  }

  /// Returns the school open/close window for the given date, or null if the
  /// school is closed that day or no resolver has loaded yet.
  (TimeOfDay, TimeOfDay)? _schoolHoursForDate(DateTime forDate) {
    final hours = schoolHoursResolver?.hoursFor(forDate);
    if (hours == null) return null;
    return (hours.startTimeOfDay, hours.endTimeOfDay);
  }

  /// Returns the school window for [weekday] (1..7, Monday-first). Iterates
  /// forward up to 7 days starting from [date] to find a real matching weekday.
  (TimeOfDay, TimeOfDay)? _schoolHoursForWeekday(int weekday) {
    for (var i = 0; i < 7; i++) {
      final probe = date.add(Duration(days: i));
      if (probe.weekday == weekday) {
        return _schoolHoursForDate(probe);
      }
    }
    return null;
  }

  AddShiftState copyWith({
    DateTime? date,
    Object? untilDate = _unset,
    Object? selectedClassroomCode = _unset,
    Object? selectedStaffCode = _unset,
    Object? shiftStart = _unset,
    Object? shiftEnd = _unset,
    Object? breakStart = _unset,
    Object? breakEnd = _unset,
    bool? repeatOn,
    Set<String>? selectedDays,
    bool? publish,
    bool? saving,
    bool? noScheduleForSelectedDate,
    SchoolHoursResolver? schoolHoursResolver,
    List<Classroom>? adminClassrooms,
    Object? untilDateError = _unset,
    Object? shiftStartError = _unset,
    Object? shiftEndError = _unset,
    Object? breakStartError = _unset,
    Object? breakEndError = _unset,
    Object? daysError = _unset,
    Object? schoolHoursError = _unset,
  }) {
    return AddShiftState(
      date: date ?? this.date,
      untilDate: identical(untilDate, _unset)
          ? this.untilDate
          : untilDate as DateTime?,
      selectedClassroomCode: identical(selectedClassroomCode, _unset)
          ? this.selectedClassroomCode
          : selectedClassroomCode as String?,
      selectedStaffCode: identical(selectedStaffCode, _unset)
          ? this.selectedStaffCode
          : selectedStaffCode as String?,
      shiftStart: identical(shiftStart, _unset)
          ? this.shiftStart
          : shiftStart as TimeOfDay?,
      shiftEnd:
          identical(shiftEnd, _unset) ? this.shiftEnd : shiftEnd as TimeOfDay?,
      breakStart: identical(breakStart, _unset)
          ? this.breakStart
          : breakStart as TimeOfDay?,
      breakEnd: identical(breakEnd, _unset)
          ? this.breakEnd
          : breakEnd as TimeOfDay?,
      repeatOn: repeatOn ?? this.repeatOn,
      selectedDays: selectedDays ?? this.selectedDays,
      publish: publish ?? this.publish,
      saving: saving ?? this.saving,
      noScheduleForSelectedDate:
          noScheduleForSelectedDate ?? this.noScheduleForSelectedDate,
      schoolHoursResolver: schoolHoursResolver ?? this.schoolHoursResolver,
      adminClassrooms: adminClassrooms ?? this.adminClassrooms,
      untilDateError: identical(untilDateError, _unset)
          ? this.untilDateError
          : untilDateError as String?,
      shiftStartError: identical(shiftStartError, _unset)
          ? this.shiftStartError
          : shiftStartError as String?,
      shiftEndError: identical(shiftEndError, _unset)
          ? this.shiftEndError
          : shiftEndError as String?,
      breakStartError: identical(breakStartError, _unset)
          ? this.breakStartError
          : breakStartError as String?,
      breakEndError: identical(breakEndError, _unset)
          ? this.breakEndError
          : breakEndError as String?,
      daysError:
          identical(daysError, _unset) ? this.daysError : daysError as String?,
      schoolHoursError: identical(schoolHoursError, _unset)
          ? this.schoolHoursError
          : schoolHoursError as String?,
    );
  }

  @override
  List<Object?> get props => [
        date,
        untilDate,
        selectedClassroomCode,
        selectedStaffCode,
        shiftStart,
        shiftEnd,
        breakStart,
        breakEnd,
        repeatOn,
        selectedDays,
        publish,
        saving,
        noScheduleForSelectedDate,
        schoolHoursResolver,
        adminClassrooms,
        untilDateError,
        shiftStartError,
        shiftEndError,
        breakStartError,
        breakEndError,
        daysError,
        schoolHoursError,
      ];
}

/// Sentinel for [AddShiftState.copyWith] so callers can distinguish "leave the
/// field unchanged" from "explicitly set it to null".
const Object _unset = Object();
