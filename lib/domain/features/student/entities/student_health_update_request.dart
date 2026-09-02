import 'package:equatable/equatable.dart';

/// Typed request for updating a student's health details.
///
/// Replaces the raw `Map<String, dynamic> body` that the two health-edit views
/// used to build inline. JSON/payload shaping stays at the data-layer boundary:
/// the repository calls [toPayload] to hand the datasource the exact Map it has
/// always received.
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

  /// Reproduces the exact Map the views used to build, key-for-key.
  Map<String, dynamic> toPayload() => {
    'allergy': allergy,
    'medications': medications,
    'dietRestrictions': dietRestrictions,
    'photoPermission': photoPermission,
  };

  @override
  List<Object?> get props => [
    allergy,
    medications,
    dietRestrictions,
    photoPermission,
  ];
}
