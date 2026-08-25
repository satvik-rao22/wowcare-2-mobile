import 'package:equatable/equatable.dart';

/// Pure-domain representation of a student's health details.
class StudentHealth extends Equatable {
  const StudentHealth({
    this.allergy,
    this.medications,
    this.dietRestrictions,
    this.photoPermission,
  });

  final String? allergy;
  final String? medications;
  final String? dietRestrictions;
  final bool? photoPermission;

  @override
  List<Object?> get props => [
    allergy,
    medications,
    dietRestrictions,
    photoPermission,
  ];
}
