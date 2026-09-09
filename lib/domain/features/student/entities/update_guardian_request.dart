import 'package:equatable/equatable.dart';

/// Typed request for the guardian PATCH, replacing the raw
/// `Map<String, dynamic> fields` the repository contract used to take. The two
/// callers build slightly different bodies (the edit-guardian flow also sends
/// `code`, an optional `relationshipDescription`, and `updatedBy`; the custody
/// flow omits them), so those three are optional and the data-layer mapper
/// includes them only when present. Pure domain — payload shaping lives in
/// `data/features/student/mappers/update_guardian_request_mapper.dart`.
class UpdateGuardianRequest extends Equatable {
  const UpdateGuardianRequest({
    required this.userCode,
    required this.schoolCode,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.relationToStudent,
    required this.primaryContact,
    required this.legalCustody,
    this.code,
    this.relationshipDescription,
    this.updatedBy,
  });

  final String userCode;
  final String schoolCode;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String relationToStudent;
  final bool primaryContact;
  final bool legalCustody;

  /// Guardian code echoed in the body (edit-guardian flow only).
  final String? code;

  /// Free-text relationship description (only when relation is "Other").
  final String? relationshipDescription;

  /// Who performed the edit (edit-guardian flow only).
  final String? updatedBy;

  @override
  List<Object?> get props => [
        userCode,
        schoolCode,
        studentCode,
        firstName,
        lastName,
        email,
        mobile,
        relationToStudent,
        primaryContact,
        legalCustody,
        code,
        relationshipDescription,
        updatedBy,
      ];
}
