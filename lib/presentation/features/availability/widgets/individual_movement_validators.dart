import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';

/// PRD-aligned validation helpers (no UI).
class IndividualMovementValidators {
  IndividualMovementValidators._();

  static DateTime dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Same student, same calendar day, same from & to => duplicate.
  static bool isDuplicateMovement({
    required List<MovementItem> existing,
    required String studentName,
    required DateTime movementDate,
    required String fromClassroom,
    required String toClassroom,
    int? excludeId,
  }) {
    final day = dateOnly(movementDate);
    final from = fromClassroom.trim();
    final to = toClassroom.trim();
    final student = studentName.trim();
    for (final m in existing) {
      if (excludeId != null && m.id == excludeId) continue;
      if (m.name.trim() != student) continue;
      if (dateOnly(m.movementDate) != day) continue;
      if (m.fromClassroom.trim() != from) continue;
      if (m.toClassroom.trim() != to) continue;
      return true;
    }
    return false;
  }

  static bool hasIdenticalFromAndTo(String fromClassroom, String toClassroom) {
    return fromClassroom.trim() == toClassroom.trim();
  }

  /// Pending item cannot be confirmed when still rejected unless user edits (handled at flow level).
  static String? validateMoveToNextClassroomForm({
    required String? student,
    required String? fromClassroom,
    required String? toClassroom,
    required DateTime? movementDate,
    required List<MovementItem> existing,
    int? excludeId,
  }) {
    if (student == null || student.trim().isEmpty) {
      return 'Please select a student';
    }
    if (fromClassroom == null || fromClassroom.trim().isEmpty) {
      return 'Please select current classroom';
    }
    if (toClassroom == null || toClassroom.trim().isEmpty) {
      return 'Please select next classroom';
    }
    if (movementDate == null) {
      return 'Movement date is required';
    }
    if (hasIdenticalFromAndTo(fromClassroom, toClassroom)) {
      return 'From and to classroom cannot be the same';
    }
    if (isDuplicateMovement(
      existing: existing,
      studentName: student,
      movementDate: movementDate,
      fromClassroom: fromClassroom,
      toClassroom: toClassroom,
      excludeId: excludeId,
    )) {
      return 'This student already has a movement on this date between these classrooms';
    }
    return null;
  }
}
