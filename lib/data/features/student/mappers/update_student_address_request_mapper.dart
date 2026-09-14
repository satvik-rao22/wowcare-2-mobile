import '../../../../domain/features/student/entities/update_student_address_request.dart';

/// Shapes an [UpdateStudentAddressRequest] into the exact `/address` PATCH body
/// (key-for-key as the view used to build inline). `schoolCode` is a cache hint
/// only and is intentionally NOT part of the body.
Map<String, dynamic> updateStudentAddressRequestToPayload(
  UpdateStudentAddressRequest request,
) {
  return <String, dynamic>{
    'line1': request.street,
    'line2': request.line2,
    'street': request.street,
    'city': request.city,
    'state': request.state,
    'country': request.country,
    'postalCode': request.postalCode,
    'addressType': request.addressType,
  };
}
