import '../../../../domain/features/student/entities/student_health_update_request.dart';

/// Shapes the domain [StudentHealthUpdateRequest] into the exact API payload the
/// student-health update endpoint expects. Keeps payload/JSON shaping in the
/// data layer (out of the domain entity).
Map<String, dynamic> studentHealthUpdateRequestToPayload(
  StudentHealthUpdateRequest request,
) {
  return <String, dynamic>{
    'allergy': request.allergy,
    'medications': request.medications,
    'dietRestrictions': request.dietRestrictions,
    'photoPermission': request.photoPermission,
  };
}
