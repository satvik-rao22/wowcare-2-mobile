import 'package:equatable/equatable.dart';

/// Typed request for updating a student's health details.
///
/// Replaces the raw `Map<String, dynamic> body` the two health-edit views used
/// to build inline. Payload/JSON shaping stays in the data layer — see
/// `studentHealthUpdateRequestToPayload` in
/// `data/features/student/mappers/student_health_update_request_mapper.dart`.
class StudentHealthUpdateRequest extends Equatable {
  const StudentHealthUpdateRequest({
    required this.allergy,
    required this.medications,
    required this.dietRestrictions,
    required this.photoPermission,
  });

  final String allergy;
  final String medications;
  final String dietRestrictions;
  final bool photoPermission;

  @override
  List<Object?> get props => [
    allergy,
    medications,
    dietRestrictions,
    photoPermission,
  ];
}
