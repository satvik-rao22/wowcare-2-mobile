import 'package:wowcare/redesign/core/constants/app_strings.dart';

/// Whose day the list is showing. 4a's Students / Staff switch.
enum AttendanceAudience {
  students,
  staff;

  bool get isStudents => this == AttendanceAudience.students;

  String get label => switch (this) {
    AttendanceAudience.students => AppStrings.students,
    AttendanceAudience.staff => AppStrings.staff,
  };
}
