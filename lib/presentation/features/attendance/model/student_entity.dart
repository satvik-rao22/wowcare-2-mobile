import 'tag_entity.dart';

/// Shared by every student attendance form (sign-in, sign-out, transfer,
/// mark-absent) — was 4 near-identical local classes, which forced
/// student_attendance_profile.dart to import all 4 under prefixes just to
/// construct a type-matching value for whichever form it was opening.
///
/// [photoUuid] stays nullable (as the sign-in form's original copy had it) —
/// callers that need a non-null value for display already do `?? ''` at the
/// call site. [isExpectedToday] and [tags] default to what an "unset" field
/// meant for the 3 forms that didn't originally declare them.
class StudentEntity {
  final int id;
  final String studentCode;
  final String fullName;
  final int roomId;
  final String roomName;
  final String classroomCode;
  final String? photoUuid;
  final bool isExpectedToday;
  final List<TagEntity> tags;

  StudentEntity({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    required this.classroomCode,
    this.photoUuid,
    this.isExpectedToday = true,
    this.tags = const [],
  });

  /// Matches [StaffEntity]: same [studentCode] is the same person in
  /// sets/lists even when the list is rebuilt after search/filter.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentEntity &&
          runtimeType == other.runtimeType &&
          studentCode == other.studentCode;

  @override
  int get hashCode => studentCode.hashCode;
}
