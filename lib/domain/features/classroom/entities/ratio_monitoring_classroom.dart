import 'package:equatable/equatable.dart';

/// Aggregate entity combining classroom metadata with live attendance data.
/// Used exclusively by the Ratio Monitoring dashboard card.
class RatioMonitoringClassroom extends Equatable {
  const RatioMonitoringClassroom({
    required this.code,
    required this.name,
    required this.capacity,
    required this.allowedRatio,
    required this.studentPresent,
    required this.staffPresent,
  });

  final String code;
  final String name;
  final int capacity;

  /// Maximum students-per-staff member from the classroom setup (studentsTeacherRatio).
  final int allowedRatio;

  final int studentPresent;
  final int staffPresent;

  /// Actual live student-to-staff ratio.
  /// Returns [double.infinity] when no staff are present.
  double get actualRatio =>
      staffPresent == 0 ? double.infinity : studentPresent / staffPresent;

  /// Whether the current ratio is within the allowed limit.
  ///
  /// Evaluation order:
  /// 1. `studentPresent == 0` → GREEN  (empty classroom, nothing to supervise)
  /// 2. `staffPresent == 0`   → RED   (students present but no staff → unsafe)
  /// 3. `allowedRatio <= 0`  → GREEN  (both present, no restriction configured)
  /// 4. `actualRatio <= allowedRatio` → GREEN, else RED
  bool get isRatioGood {
    // Empty classroom — nothing to supervise.
    if (studentPresent == 0) return true;
    // Students present but NO staff → always RED regardless of configured ratio.
    if (staffPresent == 0) return false;
    // Both present: if no ratio restriction configured, it's compliant.
    if (allowedRatio <= 0) return true;
    // Normal comparison: actual ratio vs allowed limit.
    return actualRatio <= allowedRatio;
  }

  @override
  List<Object?> get props =>
      [code, name, capacity, allowedRatio, studentPresent, staffPresent];
}

/// Classroom-scoped attendance counts returned by the by-classrooms summary APIs.
class ClassroomAttendanceSummaryEntry extends Equatable {
  const ClassroomAttendanceSummaryEntry({
    required this.expected,
    required this.present,
    required this.absent,
    required this.signout,
    required this.notMarked,
  });

  final int expected;
  final int present;
  final int absent;
  final int signout;
  final int notMarked;

  @override
  List<Object?> get props => [expected, present, absent, signout, notMarked];
}
