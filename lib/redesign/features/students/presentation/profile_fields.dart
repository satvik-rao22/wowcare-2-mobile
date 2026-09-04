import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/students_formats.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// Which rows each detail card on 5c shows, and in what order.
///
/// It lives beside the screen rather than in the model because it is a
/// reading decision, not a record: the same [StudentProfileRecord] would be
/// laid out differently on a tablet, and nothing in the model should have to
/// know that.
abstract final class ProfileFields {
  /// Profile · About.
  static List<InfoRow> about(StudentProfileRecord record) {
    final student = record.student;
    return <InfoRow>[
      InfoRow(
        StudentsStrings.fieldStatus,
        record.activeSinceLabel.isEmpty
            ? student.status.label
            : StudentsStrings.activeSince(record.activeSinceLabel),
      ),
      InfoRow(StudentsStrings.fieldClassroom, student.classroomName),
      if (student.tags.isNotEmpty)
        InfoRow(
          StudentsStrings.fieldTags,
          student.tags.map((t) => t.label).join(', '),
          tone: student.tags.any((t) => t.tone == TagTone.allergy)
              ? InfoTone.danger
              : InfoTone.ink,
        ),
      InfoRow(StudentsStrings.fieldGender, _orNotRecorded(record.gender)),
      InfoRow(
        StudentsStrings.fieldBirthDate,
        StudentsStrings.birthDateWithAge(
          StudentsFormats.date(student.dateOfBirth),
          student.age,
        ),
      ),
      InfoRow(
        StudentsStrings.fieldSchedule,
        _orNotRecorded(student.scheduleLabel),
      ),
      InfoRow(
        StudentsStrings.fieldFte,
        _orNotRecorded(record.fullTimeEquivalent),
      ),
      InfoRow(StudentsStrings.fieldCustody, _orNotRecorded(record.custody)),
      InfoRow(
        StudentsStrings.fieldSubsidy,
        record.hasStateSubsidy ? StudentsStrings.yes : StudentsStrings.no,
      ),
      InfoRow(
        StudentsStrings.fieldSibling,
        record.siblingLabel ?? StudentsStrings.none,
        tone: record.siblingLabel == null ? InfoTone.muted : InfoTone.ink,
      ),
      InfoRow(StudentsStrings.fieldAddress, _orNotRecorded(record.address)),
      if (student.movementLabel != null)
        InfoRow(StudentsStrings.fieldMoves, student.movementLabel!),
      InfoRow(
        StudentsStrings.fieldNotes,
        _orNotRecorded(record.notes),
        tone: InfoTone.muted,
      ),
    ];
  }

  /// Health · Health.
  static List<InfoRow> health(StudentHealthInfo health) => <InfoRow>[
    InfoRow(
      StudentsStrings.fieldAllergies,
      health.allergies ?? StudentsStrings.none,
      tone: health.allergies == null ? InfoTone.muted : InfoTone.danger,
    ),
    InfoRow(
      StudentsStrings.fieldMedications,
      _orNotRecorded(health.medications ?? ''),
    ),
    InfoRow(
      StudentsStrings.fieldDiet,
      _orNotRecorded(health.dietaryRestrictions ?? ''),
    ),
    InfoRow(
      StudentsStrings.fieldPhotoPermission,
      health.hasPhotoPermission
          ? StudentsStrings.permissionGiven
          : StudentsStrings.permissionWithheld,
    ),
  ];

  /// Health · Physician.
  static List<InfoRow> physician(StudentPhysicianInfo physician) => <InfoRow>[
    InfoRow(StudentsStrings.fieldPhysician, physician.name),
    InfoRow(
      StudentsStrings.fieldEmail,
      _orNotRecorded(physician.email),
      tone: InfoTone.muted,
    ),
    InfoRow(StudentsStrings.fieldPhone, _orNotRecorded(physician.phone)),
    InfoRow(StudentsStrings.fieldAddress, _orNotRecorded(physician.address)),
    InfoRow(
      StudentsStrings.fieldNotes,
      _orNotRecorded(physician.notes),
      tone: InfoTone.muted,
    ),
  ];

  /// Health · Exam.
  static List<InfoRow> exam(StudentExamInfo exam) => <InfoRow>[
    InfoRow(StudentsStrings.fieldExamDate, exam.dateLabel),
    InfoRow(
      StudentsStrings.fieldStatus,
      exam.isCompleted
          ? StudentsStrings.examCompleted
          : StudentsStrings.examDue,
      tone: exam.isCompleted ? InfoTone.success : InfoTone.ink,
    ),
    InfoRow(
      StudentsStrings.fieldNotes,
      _orNotRecorded(exam.notes),
      tone: InfoTone.muted,
    ),
  ];

  /// Dates. The five the record keeps, always all five, so a blank one reads
  /// as "not set" rather than as a row that was left out.
  static List<InfoRow> dates(StudentDates dates, String classroomName) =>
      <InfoRow>[
        _dateRow(StudentsStrings.fieldEnrollment, dates.enrollmentLabel),
        _dateRow(StudentsStrings.fieldSchoolStart, dates.schoolStartLabel),
        _dateRow(
          StudentsStrings.startedIn(classroomName),
          dates.classroomStartLabel,
        ),
        _dateRow(StudentsStrings.fieldUpcomingMove, dates.upcomingMoveLabel),
        _dateRow(StudentsStrings.fieldLeaving, dates.leavingLabel),
      ];

  static InfoRow _dateRow(String label, String? value) => value == null
      ? InfoRow(label, StudentsStrings.noMovement, tone: InfoTone.muted)
      : InfoRow(label, value);

  static String _orNotRecorded(String value) =>
      value.isEmpty ? StudentsStrings.notRecorded : value;
}
