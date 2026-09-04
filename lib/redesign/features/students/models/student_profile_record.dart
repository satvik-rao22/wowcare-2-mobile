import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/students/models/attendance_day.dart';
import 'package:wowcare/redesign/features/students/models/immunization_record.dart';
import 'package:wowcare/redesign/features/students/models/student_document_item.dart';
import 'package:wowcare/redesign/features/students/models/student_person.dart';
import 'package:wowcare/redesign/features/students/models/student_summary.dart';

/// The health card (5c Health · Health). Mirrors `StudentHealth`.
@immutable
class StudentHealthInfo extends Equatable {
  const StudentHealthInfo({
    this.allergies,
    this.medications,
    this.dietaryRestrictions,
    this.hasPhotoPermission = true,
    this.canFamilyEdit = false,
  });

  /// "Peanut · severe". Null when nothing is recorded.
  final String? allergies;
  final String? medications;
  final String? dietaryRestrictions;
  final bool hasPhotoPermission;

  /// The center lets families keep health records up to date, so a guardian
  /// sees the same Edit key staff do.
  final bool canFamilyEdit;

  @override
  List<Object?> get props => [
    allergies,
    medications,
    dietaryRestrictions,
    hasPhotoPermission,
    canFamilyEdit,
  ];
}

/// The physician card (5c Health · Physician). Mirrors `StudentPhysician`.
@immutable
class StudentPhysicianInfo extends Equatable {
  const StudentPhysicianInfo({
    required this.name,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.notes = '',
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String notes;

  @override
  List<Object?> get props => [name, email, phone, address, notes];
}

/// The physical examination card (5c Health · Exam). Mirrors
/// `StudentPhysicalExam`.
@immutable
class StudentExamInfo extends Equatable {
  const StudentExamInfo({
    required this.dateLabel,
    required this.isCompleted,
    this.notes = '',
  });

  final String dateLabel;
  final bool isCompleted;
  final String notes;

  @override
  List<Object?> get props => [dateLabel, isCompleted, notes];
}

/// The five dates the record keeps (5c Dates). Mirrors
/// `StudentImportantDates`.
@immutable
class StudentDates extends Equatable {
  const StudentDates({
    this.enrollmentLabel,
    this.schoolStartLabel,
    this.classroomStartLabel,
    this.upcomingMoveLabel,
    this.leavingLabel,
  });

  final String? enrollmentLabel;
  final String? schoolStartLabel;
  final String? classroomStartLabel;
  final String? upcomingMoveLabel;
  final String? leavingLabel;

  @override
  List<Object?> get props => [
    enrollmentLabel,
    schoolStartLabel,
    classroomStartLabel,
    upcomingMoveLabel,
    leavingLabel,
  ];
}

/// One student's whole record: everything the five tabs of 5c draw.
///
/// It is one object because the profile screen fetches once and switches
/// tabs locally, which is how the existing screen behaves: the tab cards read
/// a record the profile cubit already holds rather than each fetching again.
@immutable
class StudentProfileRecord extends Equatable {
  const StudentProfileRecord({
    required this.student,
    required this.health,
    required this.dates,
    this.activeSinceLabel = '',
    this.gender = '',
    this.fullTimeEquivalent = '',
    this.custody = '',
    this.hasStateSubsidy = false,
    this.siblingLabel,
    this.address = '',
    this.notes = '',
    this.physician,
    this.exam,
    this.guardians = const <StudentPerson>[],
    this.pickups = const <StudentPerson>[],
    this.immunizations = const <ImmunizationRecord>[],
    this.attendance = const AttendanceMonth(
      name: '',
      daysIn: 0,
      absent: 0,
      hours: 0,
    ),
    this.documents = const <StudentDocumentItem>[],
  });

  final StudentSummary student;

  /// "8 Sep 2025": the school start date the Status line quotes.
  final String activeSinceLabel;
  final String gender;

  /// "100%".
  final String fullTimeEquivalent;

  /// "Both parents".
  final String custody;
  final bool hasStateSubsidy;

  /// "Sam Okafor · Sunflower". Null when there is no sibling on file.
  final String? siblingLabel;

  final String address;
  final String notes;

  final StudentHealthInfo health;
  final StudentPhysicianInfo? physician;
  final StudentExamInfo? exam;
  final StudentDates dates;

  final List<StudentPerson> guardians;
  final List<StudentPerson> pickups;
  final List<ImmunizationRecord> immunizations;
  final AttendanceMonth attendance;
  final List<StudentDocumentItem> documents;

  /// The one vaccine the top of the Immunization tab warns about, if any.
  ImmunizationRecord? get overdueImmunization {
    for (final record in immunizations) {
      if (record.status == ImmunizationStatus.overdue) return record;
    }
    return null;
  }

  /// Who is called first.
  StudentPerson? get emergencyContact {
    for (final person in guardians) {
      if (person.badgeTone == PersonBadgeTone.emergency) return person;
    }
    return null;
  }

  StudentProfileRecord copyWith({
    StudentSummary? student,
    List<StudentDocumentItem>? documents,
  }) => StudentProfileRecord(
    student: student ?? this.student,
    health: health,
    dates: dates,
    activeSinceLabel: activeSinceLabel,
    gender: gender,
    fullTimeEquivalent: fullTimeEquivalent,
    custody: custody,
    hasStateSubsidy: hasStateSubsidy,
    siblingLabel: siblingLabel,
    address: address,
    notes: notes,
    physician: physician,
    exam: exam,
    guardians: guardians,
    pickups: pickups,
    immunizations: immunizations,
    attendance: attendance,
    documents: documents ?? this.documents,
  );

  @override
  List<Object?> get props => [
    student,
    activeSinceLabel,
    gender,
    fullTimeEquivalent,
    custody,
    hasStateSubsidy,
    siblingLabel,
    address,
    notes,
    health,
    physician,
    exam,
    dates,
    guardians,
    pickups,
    immunizations,
    attendance,
    documents,
  ];
}
