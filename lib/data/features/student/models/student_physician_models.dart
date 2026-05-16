import 'package:equatable/equatable.dart';

class StudentPhysicianModel extends Equatable {
  const StudentPhysicianModel({
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

  factory StudentPhysicianModel.fromJson(Map<String, dynamic> json) {
    return StudentPhysicianModel(
      code: json['code'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      address: json['address'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

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
