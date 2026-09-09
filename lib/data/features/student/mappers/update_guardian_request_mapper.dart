import '../../../../domain/features/student/entities/update_guardian_request.dart';

/// Shapes an [UpdateGuardianRequest] into the guardian PATCH body. `code`,
/// `relationshipDescription`, and `updatedBy` are included only when present
/// (the custody flow omits them; the edit-guardian flow sends them) — key-for-key
/// as the two views used to build inline.
Map<String, dynamic> updateGuardianRequestToPayload(
  UpdateGuardianRequest request,
) {
  return <String, dynamic>{
    'userCode': request.userCode,
    if (request.code != null) 'code': request.code,
    'schoolCode': request.schoolCode,
    'studentCode': request.studentCode,
    'firstName': request.firstName,
    'lastName': request.lastName,
    'email': request.email,
    'mobile': request.mobile,
    'relationToStudent': request.relationToStudent,
    if (request.relationshipDescription != null)
      'relationshipDescription': request.relationshipDescription,
    'primaryContact': request.primaryContact,
    'legalCustody': request.legalCustody,
    if (request.updatedBy != null) 'updatedBy': request.updatedBy,
  };
}
