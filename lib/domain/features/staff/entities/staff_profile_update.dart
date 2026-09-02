import 'package:equatable/equatable.dart';

/// Typed request for updating a staff member's core profile details via
/// `PATCH /api/v1/staff/staff/my-profile/{staffCode}` (edit staff profile).
///
/// Replaces the raw `Map<String, dynamic>` body the edit-profile view used to
/// build inline. The critical fidelity requirement is the CONDITIONAL omission
/// of [jobTag] and [birthdate]: the old code added those keys only when
/// non-null, so [toPayload] omits them via a conditional spread when they are
/// null — reproducing the exact Map, byte-for-byte.
///
/// The values carried here are already transformed by the view (status and
/// designation mapped to API codes, phone reduced to digits, birthdate encoded
/// as an ISO-8601 timestamp) — this model only carries them.
class StaffProfileUpdate extends Equatable {
  const StaffProfileUpdate({
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.phoneNumber,
    required this.designation,
    this.jobTag,
    this.birthdate,
  });

  final String firstName;
  final String lastName;
  final String status;
  final String phoneNumber;
  final String designation;

  /// Omitted from the payload entirely when null (never sent as `null`).
  final String? jobTag;

  /// Backend contract key is `birthdate` (lowercase); omitted when null.
  final String? birthdate;

  /// Reproduces the exact Map the edit-profile view used to build, including
  /// the conditional omission of [jobTag]/[birthdate] when null.
  Map<String, dynamic> toPayload() => {
    'firstName': firstName,
    'lastName': lastName,
    'status': status,
    'phoneNumber': phoneNumber,
    'designation': designation,
    if (jobTag != null) 'jobTag': jobTag,
    if (birthdate != null) 'birthdate': birthdate,
  };

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    status,
    phoneNumber,
    designation,
    jobTag,
    birthdate,
  ];
}
