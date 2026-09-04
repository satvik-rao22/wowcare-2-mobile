import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// Where one vaccine dose stands. The backend's `status`, plus the overdue
/// case the due date decides.
enum ImmunizationStatus {
  completed,
  due,
  overdue,
  exempt;

  String get label => switch (this) {
    ImmunizationStatus.completed => StudentsStrings.immunCompleted,
    ImmunizationStatus.due => StudentsStrings.immunDue,
    ImmunizationStatus.overdue => StudentsStrings.immunOverdue,
    ImmunizationStatus.exempt => StudentsStrings.immunExempt,
  };
}

/// One vaccine dose on a student's record (5c Health · Immunization).
///
/// Mirrors `StudentImmunization`: `vaccineName` with its `doseNumber`,
/// `status`, `dueDate`, `administeredDate` and `exemptionReason`. The due
/// date, the status and the exemption reason are all already returned; the
/// overdue line at the top of the tab is what they were being fetched for.
@immutable
class ImmunizationRecord extends Equatable {
  const ImmunizationRecord({
    required this.name,
    required this.detail,
    required this.status,
    this.dueDateLabel,
  });

  /// "DTaP · dose 4".
  final String name;

  /// "Given 12 Sep 2025", "Was due 1 Jul 2026", "Medical exemption on file".
  final String detail;

  final ImmunizationStatus status;

  /// "1 July", for the overdue line. Null unless [status] is overdue.
  final String? dueDateLabel;

  @override
  List<Object?> get props => [name, detail, status, dueDateLabel];
}
