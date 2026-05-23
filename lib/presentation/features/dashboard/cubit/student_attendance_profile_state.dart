part of 'student_attendance_profile_cubit.dart';

enum _Status { initial, loading, loaded, error }

class StudentAttendanceProfileState extends Equatable {
  const StudentAttendanceProfileState({
    required this.status,
    required this.studentCode,
    required this.attendedDays,
    required this.attendedHours,
    required this.attendedMinutes,
    required this.totalAttendedTime,
    required this.absentDays,
    required this.fromDate,
    required this.toDate,
    required this.errorMessage,
  });

  const StudentAttendanceProfileState.initial()
    : status = _Status.initial,
      studentCode = '',
      attendedDays = 0,
      attendedHours = 0,
      attendedMinutes = 0,
      totalAttendedTime = '',
      absentDays = 0,
      fromDate = null,
      toDate = null,
      errorMessage = null;

  const StudentAttendanceProfileState.loaded({
    required String studentCode,
    required int attendedDays,
    required int attendedHours,
    required int attendedMinutes,
    required String totalAttendedTime,
    required int absentDays,
    required DateTime fromDate,
    required DateTime toDate,
  })  : status = _Status.loaded,
        studentCode = studentCode,
        attendedDays = attendedDays,
        attendedHours = attendedHours,
        attendedMinutes = attendedMinutes,
        totalAttendedTime = totalAttendedTime,
        absentDays = absentDays,
        fromDate = fromDate,
        toDate = toDate,
        errorMessage = null;

  final _Status status;
  final String studentCode;
  final int attendedDays;
  final int attendedHours;
  final int attendedMinutes;
  final String totalAttendedTime;
  final int absentDays;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? errorMessage;

  bool get isLoading => status == _Status.loading;
  bool get isLoaded => status == _Status.loaded;
  bool get isError => status == _Status.error;
  bool get isInitial => status == _Status.initial;

  StudentAttendanceProfileState copyWith({
    _Status? status,
    String? studentCode,
    int? attendedDays,
    int? attendedHours,
    int? attendedMinutes,
    String? totalAttendedTime,
    int? absentDays,
    DateTime? fromDate,
    DateTime? toDate,
    String? errorMessage,
  }) {
    return StudentAttendanceProfileState(
      status: status ?? this.status,
      studentCode: studentCode ?? this.studentCode,
      attendedDays: attendedDays ?? this.attendedDays,
      attendedHours: attendedHours ?? this.attendedHours,
      attendedMinutes: attendedMinutes ?? this.attendedMinutes,
      totalAttendedTime: totalAttendedTime ?? this.totalAttendedTime,
      absentDays: absentDays ?? this.absentDays,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    studentCode,
    attendedDays,
    attendedHours,
    attendedMinutes,
    totalAttendedTime,
    absentDays,
    fromDate,
    toDate,
    errorMessage,
  ];
}
