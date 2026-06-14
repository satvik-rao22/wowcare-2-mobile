import 'package:equatable/equatable.dart';

/// Pure-domain representation of a student's physical exam record.
class StudentPhysicalExam extends Equatable {
  const StudentPhysicalExam({
    required this.code,
    this.examDate,
    this.status,
    this.notes,
  });

  final String code;

  /// ISO date string `YYYY-MM-DD` (per backend contract).
  final String? examDate;

  /// e.g. `COMPLETED`, `DUE`.
  final String? status;
  final String? notes;

  @override
  List<Object?> get props => [code, examDate, status, notes];
}
