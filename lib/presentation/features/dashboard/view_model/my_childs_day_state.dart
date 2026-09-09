part of 'my_childs_day_cubit.dart';

enum MyChildsDayStatus { initial, loading, loaded, error }

class MyChildsDayState extends Equatable {
  const MyChildsDayState({
    required this.status,
    required this.studentCode,
    required this.fullName,
    required this.classroomName,
    required this.schoolCode,
    required this.schoolTimeZone,
    required this.todayDayOfWeek,
    required this.todayScheduleRange,
    required this.allRegularSchedules,
    required this.schoolNow,
    required this.guardianClockPin,
    required this.errorMessage,
  });

  const MyChildsDayState.initial()
    : status = MyChildsDayStatus.initial,
      studentCode = '',
      fullName = '',
      classroomName = '',
      schoolCode = '',
      schoolTimeZone = '',
      todayDayOfWeek = '',
      todayScheduleRange = '',
      allRegularSchedules = const [],
      schoolNow = null,
      guardianClockPin = '',
      errorMessage = '';

  final MyChildsDayStatus status;
  final String studentCode;
  final String fullName;
  final String classroomName;
  final String schoolCode;
  final String schoolTimeZone;

  /// "MONDAY", "TUESDAY", ... in the school calendar.
  final String todayDayOfWeek;
  final String todayScheduleRange;

  /// All weekly regular schedule entries from the dedicated schedule API.
  final List<StudentRegularScheduleEntry> allRegularSchedules;

  final DateTime? schoolNow;
  final String guardianClockPin;
  final String errorMessage;

  MyChildsDayState copyWith({
    MyChildsDayStatus? status,
    String? studentCode,
    String? fullName,
    String? classroomName,
    String? schoolCode,
    String? schoolTimeZone,
    String? todayDayOfWeek,
    String? todayScheduleRange,
    List<StudentRegularScheduleEntry>? allRegularSchedules,
    DateTime? schoolNow,
    String? guardianClockPin,
    String? errorMessage,
  }) {
    return MyChildsDayState(
      status: status ?? this.status,
      studentCode: studentCode ?? this.studentCode,
      fullName: fullName ?? this.fullName,
      classroomName: classroomName ?? this.classroomName,
      schoolCode: schoolCode ?? this.schoolCode,
      schoolTimeZone: schoolTimeZone ?? this.schoolTimeZone,
      todayDayOfWeek: todayDayOfWeek ?? this.todayDayOfWeek,
      todayScheduleRange: todayScheduleRange ?? this.todayScheduleRange,
      allRegularSchedules: allRegularSchedules ?? this.allRegularSchedules,
      schoolNow: schoolNow ?? this.schoolNow,
      guardianClockPin: guardianClockPin ?? this.guardianClockPin,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    studentCode,
    fullName,
    classroomName,
    schoolCode,
    schoolTimeZone,
    todayDayOfWeek,
    todayScheduleRange,
    allRegularSchedules,
    schoolNow,
    guardianClockPin,
    errorMessage,
  ];
}
