import 'package:equatable/equatable.dart';

class StudentProfile extends Equatable {
  const StudentProfile({
    required this.code,
    required this.schoolCode,
    required this.fullName,
    this.classroomName,
    this.scheduleByDay = const <String, String>{},
  });

  final String code;
  final String schoolCode;
  final String fullName;
  final String? classroomName;

  /// Day-of-week (MONDAY, TUESDAY, ...) -> "start - end".
  final Map<String, String> scheduleByDay;

  @override
  List<Object?> get props => [
    code,
    schoolCode,
    fullName,
    classroomName,
    scheduleByDay,
  ];
}
