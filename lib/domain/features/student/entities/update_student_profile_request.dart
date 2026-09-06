import 'package:equatable/equatable.dart';

/// Typed request for the core student-profile PATCH, replacing the raw
/// `Map<String, dynamic> fields` the repository contract used to take. Pure
/// domain — payload shaping lives in the data layer (see
/// `data/features/student/mappers/update_student_profile_request_mapper.dart`).
class UpdateStudentProfileRequest extends Equatable {
  const UpdateStudentProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.status,
    this.dob,
    this.notes = '',
    this.subsidy = false,
    this.gender,
    required this.classroomCode,
    required this.classroomName,
    this.schoolCode,
  });

  final String firstName;
  final String lastName;

  /// API status enum, e.g. `ACTIVE`.
  final String status;

  /// `yyyy-MM-dd`, or null to omit from the body.
  final String? dob;
  final String notes;
  final bool subsidy;

  /// API gender enum (already upper-cased), or null to omit from the body.
  final String? gender;

  final String classroomCode;
  final String classroomName;

  /// Optional school code — a cache-invalidation hint for the repository, not
  /// part of the API body.
  final String? schoolCode;

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        status,
        dob,
        notes,
        subsidy,
        gender,
        classroomCode,
        classroomName,
        schoolCode,
      ];
}
