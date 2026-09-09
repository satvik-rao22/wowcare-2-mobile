import '../../../../domain/features/student/entities/update_student_profile_request.dart';

/// Shapes an [UpdateStudentProfileRequest] into the exact `/profile` PATCH body
/// (key-for-key as the view used to build inline): `dob`/`gender` are omitted
/// when null, and `classroom` is a nested `{code, name}` object. `schoolCode` is
/// a cache hint only and is NOT part of the body.
Map<String, dynamic> updateStudentProfileRequestToPayload(
  UpdateStudentProfileRequest request,
) {
  return <String, dynamic>{
    'firstName': request.firstName,
    'lastName': request.lastName,
    'status': request.status,
    if (request.dob != null) 'dob': request.dob,
    'notes': request.notes,
    'subsidy': request.subsidy,
    if (request.gender != null) 'gender': request.gender,
    'classroom': <String, dynamic>{
      'code': request.classroomCode,
      'name': request.classroomName,
    },
  };
}
