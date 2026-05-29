import 'package:equatable/equatable.dart';

/// Pure-domain representation of a student's pickup contact.
///
/// No serialisation here — JSON parsing lives in the data layer
/// (`StudentPickupModel`) and is translated via `StudentPickupModelMapper`.
class StudentPickup extends Equatable {
  const StudentPickup({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.relation,
    this.code,
    this.studentCode,
    this.clockPin,
    this.relationshipDescription,
    this.pickupType,
    this.carpoolId,
  });

  final String? code;
  final String? studentCode;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String relation;
  final String? clockPin;
  final String? relationshipDescription;
  final String? pickupType;
  final String? carpoolId;

  String get fullName => ('$firstName $lastName').trim();

  @override
  List<Object?> get props => [
        code,
        studentCode,
        firstName,
        lastName,
        email,
        phoneNumber,
        relation,
        clockPin,
        relationshipDescription,
        pickupType,
        carpoolId,
      ];
}
