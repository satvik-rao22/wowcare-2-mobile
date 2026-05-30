import 'package:equatable/equatable.dart';

/// Pure-domain representation of a student's physician contact.
class StudentPhysician extends Equatable {
  const StudentPhysician({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.specialty,
    required this.notes,
    required this.status,
  });

  final String code;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address;
  final String specialty;
  final String notes;
  final String status;

  String get fullName => ('$firstName $lastName').trim();

  @override
  List<Object?> get props => [
        code,
        firstName,
        lastName,
        email,
        phoneNumber,
        address,
        specialty,
        notes,
        status,
      ];
}
