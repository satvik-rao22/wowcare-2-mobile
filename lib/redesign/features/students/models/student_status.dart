import 'package:wowcare/redesign/features/students/students_strings.dart';

/// Where a student is in their enrollment. The backend's `status` field,
/// which the roster's Status filter picks one of.
enum StudentStatus {
  /// On the roster today, counted in the ratios.
  active,

  /// Enrolled, with a school start date that has not arrived.
  upcoming,

  /// Off the roster. The record, its documents and its history all stay.
  inactive;

  String get label => switch (this) {
    StudentStatus.active => StudentsStrings.activePill,
    StudentStatus.upcoming => StudentsStrings.upcomingPill,
    StudentStatus.inactive => StudentsStrings.inactivePill,
  };
}
