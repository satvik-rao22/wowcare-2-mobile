import 'package:equatable/equatable.dart';

/// Pure-domain representation of a student's immunization (vaccine dose) record.
class StudentImmunization extends Equatable {
  const StudentImmunization({
    required this.code,
    required this.studentCode,
    required this.vaccineName,
    required this.vaccineDoseCode,
    required this.doseNumber,
    required this.status,
    this.dueDate,
    this.administeredDate,
    this.exemptionReason,
    this.notes,
  });

  final String code;
  final String studentCode;
  final String vaccineName;
  final String vaccineDoseCode;
  final int doseNumber;
  final String? dueDate;
  final String? administeredDate;
  final String status;
  final String? exemptionReason;
  final String? notes;

  @override
  List<Object?> get props => [
        code,
        studentCode,
        vaccineName,
        vaccineDoseCode,
        doseNumber,
        dueDate,
        administeredDate,
        status,
        exemptionReason,
        notes,
      ];
}
