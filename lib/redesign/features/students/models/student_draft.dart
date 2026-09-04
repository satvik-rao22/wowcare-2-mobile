import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/students/models/schedule_entry.dart';
import 'package:wowcare/redesign/features/students/models/student_status.dart';
import 'package:wowcare/redesign/features/students/models/student_tag.dart';

/// Every field a form on 5d or 5e can complain about.
enum StudentField {
  firstName,
  lastName,
  classroom,
  birthDate,
  schoolStartDate,
  guardian,
  relation,
  guardianName,
  guardianEmail,
  guardianPhone,
}

/// Where step two's parent comes from.
enum GuardianSource { existing, create }

/// A student being written: the add wizard's three steps (5d) and the edit
/// form (5e) fill the same object.
///
/// The wizard's own `createStudent` call takes first name, last name, status,
/// classroom code, date of birth and school start date; the parent link and
/// the schedule are separate calls the two optional steps make, which is why
/// they can be skipped.
@immutable
class StudentDraft extends Equatable {
  const StudentDraft({
    this.status = StudentStatus.active,
    this.firstName = '',
    this.lastName = '',
    this.classroomName,
    this.dateOfBirth,
    this.schoolStartDate,
    this.siblingId,
    this.siblingLabel,
    this.guardianSource = GuardianSource.existing,
    this.guardianId,
    this.guardianLabel,
    this.guardianName = '',
    this.guardianEmail = '',
    this.guardianPhone = '',
    this.relation,
    this.isEmergencyContact = true,
    this.hasLegalCustody = true,
    this.sameTimesEveryDay = true,
    this.week = const <ScheduleEntry>[],
    this.tags = const <StudentTag>[],
    this.notes = '',
  });

  // --- Step one, and the top of the edit form -------------------------------

  final StudentStatus status;
  final String firstName;
  final String lastName;
  final String? classroomName;
  final DateTime? dateOfBirth;

  /// Only an upcoming student needs one, and it must be today or later.
  final DateTime? schoolStartDate;

  final String? siblingId;

  /// "Sam Okafor · Sunflower". Null reads "None yet".
  final String? siblingLabel;

  // --- Step two -------------------------------------------------------------

  final GuardianSource guardianSource;
  final String? guardianId;

  /// "Wei Chen · wei.chen@gmail.com", once one is picked.
  final String? guardianLabel;

  /// A parent being created rather than linked.
  final String guardianName;
  final String guardianEmail;
  final String guardianPhone;

  final String? relation;
  final bool isEmergencyContact;
  final bool hasLegalCustody;

  // --- Step three -----------------------------------------------------------

  final bool sameTimesEveryDay;
  final List<ScheduleEntry> week;

  // --- Edit only ------------------------------------------------------------

  final List<StudentTag> tags;
  final String notes;

  String get fullName => '$firstName $lastName'.trim();

  StudentDraft copyWith({
    StudentStatus? status,
    String? firstName,
    String? lastName,
    String? classroomName,
    DateTime? dateOfBirth,
    DateTime? schoolStartDate,
    String? siblingId,
    String? siblingLabel,
    GuardianSource? guardianSource,
    String? guardianId,
    String? guardianLabel,
    String? guardianName,
    String? guardianEmail,
    String? guardianPhone,
    String? relation,
    bool? isEmergencyContact,
    bool? hasLegalCustody,
    bool? sameTimesEveryDay,
    List<ScheduleEntry>? week,
    List<StudentTag>? tags,
    String? notes,
    bool clearSibling = false,
    bool clearGuardian = false,
    bool clearSchoolStartDate = false,
  }) => StudentDraft(
    status: status ?? this.status,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    classroomName: classroomName ?? this.classroomName,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    schoolStartDate: clearSchoolStartDate
        ? null
        : schoolStartDate ?? this.schoolStartDate,
    siblingId: clearSibling ? null : siblingId ?? this.siblingId,
    siblingLabel: clearSibling ? null : siblingLabel ?? this.siblingLabel,
    guardianSource: guardianSource ?? this.guardianSource,
    guardianId: clearGuardian ? null : guardianId ?? this.guardianId,
    guardianLabel: clearGuardian ? null : guardianLabel ?? this.guardianLabel,
    guardianName: guardianName ?? this.guardianName,
    guardianEmail: guardianEmail ?? this.guardianEmail,
    guardianPhone: guardianPhone ?? this.guardianPhone,
    relation: relation ?? this.relation,
    isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
    hasLegalCustody: hasLegalCustody ?? this.hasLegalCustody,
    sameTimesEveryDay: sameTimesEveryDay ?? this.sameTimesEveryDay,
    week: week ?? this.week,
    tags: tags ?? this.tags,
    notes: notes ?? this.notes,
  );

  @override
  List<Object?> get props => [
    status,
    firstName,
    lastName,
    classroomName,
    dateOfBirth,
    schoolStartDate,
    siblingId,
    siblingLabel,
    guardianSource,
    guardianId,
    guardianLabel,
    guardianName,
    guardianEmail,
    guardianPhone,
    relation,
    isEmergencyContact,
    hasLegalCustody,
    sameTimesEveryDay,
    week,
    tags,
    notes,
  ];
}
