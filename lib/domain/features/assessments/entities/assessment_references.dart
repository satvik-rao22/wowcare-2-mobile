import 'package:equatable/equatable.dart';

/// Lightweight reference snapshots of the Classroom and Student entities that
/// the Assessments module needs for scoping and roll-ups.
///
/// The canonical Student/Classroom records are owned by their own modules and
/// served by the (currently offline) backend. These snapshots carry the few
/// fields assessments need — including `ageGroup` (classroom) and `avatar`/
/// `status` (student) that the lean app-side `Classroom`/`Student` entities do
/// not hold — and are seeded from the bundled mock data during development.
/// When the backend returns, these can be hydrated from the real entities.

/// A classroom as referenced by the Assessments module.
class AssessmentClassroom extends Equatable {
  const AssessmentClassroom({
    required this.code,
    required this.name,
    this.ageGroup = '',
    this.schoolId = '',
  });

  /// Stable classroom identifier (matches `Classroom.code` elsewhere).
  final String code;
  final String name;

  /// Developmental age band, e.g. "0–12m", "3–4y" (PRD §4 glossary).
  final String ageGroup;
  final String schoolId;

  @override
  List<Object?> get props => [code, name, ageGroup, schoolId];
}

/// A student as referenced by the Assessments module.
class AssessmentStudent extends Equatable {
  const AssessmentStudent({
    required this.code,
    required this.name,
    required this.classroomCode,
    this.dateOfBirth,
    this.avatarUrl,
    this.status = 'ACTIVE',
    this.schoolId = '',
    this.tags = const <String>[],
  });

  /// Stable student identifier (matches `Student.code` elsewhere).
  final String code;
  final String name;

  /// Code of the classroom this student belongs to. Classrooms scope *who a
  /// teacher can see*; which milestones the child is assessed against is
  /// resolved from [dateOfBirth] against the school's age bands.
  final String classroomCode;

  /// Date of birth — the input to age-band resolution. Null when the source
  /// record has no DOB; such students resolve to no band and can't be scored.
  final DateTime? dateOfBirth;
  final String? avatarUrl;
  final String status;
  final String schoolId;

  /// Local mock tags (e.g. "IEP", "ESL") used to filter the student list.
  final List<String> tags;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  /// Age in whole months as of [date] (calendar-aware: the month count only
  /// ticks over once the day-of-month is reached). Null without a DOB or for
  /// dates before birth.
  int? ageInMonthsAt(DateTime date) {
    final dob = dateOfBirth;
    if (dob == null) return null;
    var months = (date.year - dob.year) * 12 + (date.month - dob.month);
    if (date.day < dob.day) months -= 1;
    return months < 0 ? null : months;
  }

  /// Up to two initials for the avatar fallback (FR-SA-04).
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  List<Object?> get props =>
      [code, name, classroomCode, dateOfBirth, status, schoolId, tags];
}
