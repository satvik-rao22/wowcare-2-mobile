part of 'edit_shift_cubit.dart';

/// Immutable form + async state for [EditShiftScreen]. Mirrors
/// [AddShiftState] but for editing an existing shift: the staff is fixed (the
/// edit flow never re-picks staff) and the series-vs-single distinction is
/// driven by the cubit's [EditShiftCubit.isSeriesMode], not a UI toggle.
class EditShiftState extends Equatable {
  const EditShiftState({
    this.date,
    this.untilDate,
    this.selectedClassroomCode,
    this.shiftStart,
    this.shiftEnd,
    this.breakStart,
    this.breakEnd,
    this.selectedDays = const <String>{},
    this.publish = true,
    this.saving = false,
    this.schoolHoursResolver,
    this.adminClassrooms = const <Classroom>[],
    this.shiftStartError,
    this.shiftEndError,
    this.breakStartError,
    this.breakEndError,
    this.untilDateError,
    this.daysError,
    this.schoolHoursError,
  });

  final DateTime? date;
  final DateTime? untilDate;
  final String? selectedClassroomCode;

  final TimeOfDay? shiftStart;
  final TimeOfDay? shiftEnd;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;

  final Set<String> selectedDays;
  final bool publish;
  final bool saving;

  final SchoolHoursResolver? schoolHoursResolver;
  final List<Classroom> adminClassrooms;

  final String? shiftStartError;
  final String? shiftEndError;
  final String? breakStartError;
  final String? breakEndError;
  final String? untilDateError;
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

  (ScheduleTime, ScheduleTime)? _schoolHoursForDate(DateTime forDate) {
    final hours = schoolHoursResolver?.hoursFor(forDate);
    if (hours == null) return null;
    return (hours.openTime, hours.closeTime);
  }

  (ScheduleTime, ScheduleTime)? _schoolHoursForWeekday(int weekday) {
    final anchor = date ?? schedulingSchoolToday();
    for (var i = 0; i < 7; i++) {
      final probe = anchor.add(Duration(days: i));
      if (probe.weekday == weekday) {
        return _schoolHoursForDate(probe);
      }
    }
    return null;
  }

  EditShiftState copyWith({
    DateTime? date,
    Object? untilDate = _unset,
    Object? selectedClassroomCode = _unset,
    Object? shiftStart = _unset,
    Object? shiftEnd = _unset,
    Object? breakStart = _unset,
    Object? breakEnd = _unset,
    Set<String>? selectedDays,
    bool? publish,
    bool? saving,
    SchoolHoursResolver? schoolHoursResolver,
    List<Classroom>? adminClassrooms,
    Object? shiftStartError = _unset,
    Object? shiftEndError = _unset,
    Object? breakStartError = _unset,
    Object? breakEndError = _unset,
    Object? untilDateError = _unset,
    Object? daysError = _unset,
    Object? schoolHoursError = _unset,
  }) {
    return EditShiftState(
      date: date ?? this.date,
      untilDate: identical(untilDate, _unset)
          ? this.untilDate
          : untilDate as DateTime?,
      selectedClassroomCode: identical(selectedClassroomCode, _unset)
          ? this.selectedClassroomCode
          : selectedClassroomCode as String?,
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
      selectedDays: selectedDays ?? this.selectedDays,
      publish: publish ?? this.publish,
      saving: saving ?? this.saving,
      schoolHoursResolver: schoolHoursResolver ?? this.schoolHoursResolver,
      adminClassrooms: adminClassrooms ?? this.adminClassrooms,
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
      untilDateError: identical(untilDateError, _unset)
          ? this.untilDateError
          : untilDateError as String?,
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
        shiftStart,
        shiftEnd,
        breakStart,
        breakEnd,
        selectedDays,
        publish,
        saving,
        schoolHoursResolver,
        adminClassrooms,
        shiftStartError,
        shiftEndError,
        breakStartError,
        breakEndError,
        untilDateError,
        daysError,
        schoolHoursError,
      ];
}

/// Sentinel for [EditShiftState.copyWith] so callers can distinguish "leave
/// the field unchanged" from "explicitly set it to null".
const Object _unset = Object();
