import 'package:equatable/equatable.dart';

class StudentPickupModel extends Equatable {
  const StudentPickupModel({
    this.code,
    this.studentCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.relation,
    this.clockPin,
  });

  final String? code;
  final String? studentCode;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String relation;
  final String? clockPin;

  String get fullName => ('$firstName $lastName').trim();

  factory StudentPickupModel.fromJson(Map<String, dynamic> json) {
    return StudentPickupModel(
      code: (json['code'] ?? json['pickupCode'] ?? json['pickup_code']) as String?,
      studentCode: json['studentCode'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
      clockPin: json['clockPin'] as String?,
    );
  }

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
      ];
}

