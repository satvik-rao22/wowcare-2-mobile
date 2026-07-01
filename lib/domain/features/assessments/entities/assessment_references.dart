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
    this.avatarUrl,
    this.status = 'ACTIVE',
    this.schoolId = '',
    this.tags = const <String>[],
  });

  /// Stable student identifier (matches `Student.code` elsewhere).
  final String code;
  final String name;

  /// Code of the classroom this student belongs to.
  final String classroomCode;
  final String? avatarUrl;
  final String status;
  final String schoolId;

  /// Local mock tags (e.g. "IEP", "ESL") used to filter the student list.
  final List<String> tags;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

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
      [code, name, classroomCode, status, schoolId, tags];
}
