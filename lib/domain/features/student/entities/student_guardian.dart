import 'package:equatable/equatable.dart';

/// Pure-domain representation of a student's guardian/parent.
class StudentGuardian extends Equatable {
  const StudentGuardian({
    required this.guardianCode,
    required this.userCode,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.email,
    required this.relationToStudent,
    required this.primaryContact,
    required this.legalCustody,
    this.clockPin,
  });

  final String guardianCode;
  final String userCode;
  final String firstName;
  final String lastName;
  final String mobile;
  final String email;
  final String? clockPin;
  final String relationToStudent;
  final bool primaryContact;
  final bool legalCustody;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
        guardianCode,
        userCode,
        firstName,
        lastName,
        mobile,
        email,
        clockPin,
        relationToStudent,
        primaryContact,
        legalCustody,
      ];
}
