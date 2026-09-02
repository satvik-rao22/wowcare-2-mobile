part of 'student_attendance_profile_fetch_cubit.dart';

class StudentAttendanceProfileState extends Equatable {
  const StudentAttendanceProfileState({
    this.startDate,
    this.endDate,
    this.isAttendancesLoading = false,
    this.isAbsentDaysLoading = false,
    this.isStudentLoading = false,
    this.showAbsentDays = false,
    this.attendances = const [],
    this.absentDays = const [],
    this.student,
    this.attendanceReport,
    this.activeStudentCode = '',
    this.todayStatusRaw,
    this.isTodayStatusLoading = false,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final bool isAttendancesLoading;
  final bool isAbsentDaysLoading;
  final bool isStudentLoading;
  final bool showAbsentDays;
  final List<StudentProfileAttendanceRecord> attendances;
  final List<StudentProfileAbsentDayRecord> absentDays;
  final StudentProfileCardModel? student;
  final StudentProfileAttendanceReportModel? attendanceReport;
  final String activeStudentCode;
  final String? todayStatusRaw;
  final bool isTodayStatusLoading;

  StudentAttendanceProfileState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? isAttendancesLoading,
    bool? isAbsentDaysLoading,
    bool? isStudentLoading,
    bool? showAbsentDays,
    List<StudentProfileAttendanceRecord>? attendances,
    List<StudentProfileAbsentDayRecord>? absentDays,
    StudentProfileCardModel? student,
    StudentProfileAttendanceReportModel? attendanceReport,
    String? activeStudentCode,
    String? todayStatusRaw,
    bool clearTodayStatusRaw = false,
    bool? isTodayStatusLoading,
  }) {
    return StudentAttendanceProfileState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAttendancesLoading: isAttendancesLoading ?? this.isAttendancesLoading,
      isAbsentDaysLoading: isAbsentDaysLoading ?? this.isAbsentDaysLoading,
      isStudentLoading: isStudentLoading ?? this.isStudentLoading,
      showAbsentDays: showAbsentDays ?? this.showAbsentDays,
      attendances: attendances ?? this.attendances,
      absentDays: absentDays ?? this.absentDays,
      student: student ?? this.student,
      attendanceReport: attendanceReport ?? this.attendanceReport,
      activeStudentCode: activeStudentCode ?? this.activeStudentCode,
      todayStatusRaw: clearTodayStatusRaw
          ? null
          : (todayStatusRaw ?? this.todayStatusRaw),
      isTodayStatusLoading: isTodayStatusLoading ?? this.isTodayStatusLoading,
    );
  }

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    isAttendancesLoading,
    isAbsentDaysLoading,
    isStudentLoading,
    showAbsentDays,
    attendances,
    absentDays,
    student,
    attendanceReport,
    activeStudentCode,
    todayStatusRaw,
    isTodayStatusLoading,
  ];
}
