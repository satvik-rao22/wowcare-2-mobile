import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'student_physician_models.g.dart';

@JsonSerializable(createToJson: false)
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

  @JsonKey(defaultValue: '') final String code;
  @JsonKey(defaultValue: '') final String firstName;
  @JsonKey(defaultValue: '') final String lastName;
  @JsonKey(defaultValue: '') final String email;
  @JsonKey(defaultValue: '') final String phoneNumber;
  @JsonKey(defaultValue: '') final String address;
  @JsonKey(defaultValue: '') final String specialty;
  @JsonKey(defaultValue: '') final String notes;
  @JsonKey(defaultValue: '') final String status;

  String get fullName => ('$firstName $lastName').trim();

  factory StudentPhysicianModel.fromJson(Map<String, dynamic> json) =>
      _$StudentPhysicianModelFromJson(json);

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

