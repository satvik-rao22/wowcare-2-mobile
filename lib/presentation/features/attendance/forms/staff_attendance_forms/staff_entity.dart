// Mock staff entity for UI-only implementation
class StaffEntity {
  final int id;
  final String name;
  final int primaryRoomId;
  final String? classroomCode;
  final String? classroomName;
  final String? photoUuid;
  final String designation;
  /// Optional staffCode for integration with attendance APIs.
  final String? staffCode;

  /// From sign-in form list / daily view API; used when building sign-in payloads.
  final bool isExpectedToday;

  StaffEntity({
    required this.id,
    required this.name,
    required this.primaryRoomId,
    this.classroomCode,
    this.classroomName,
    this.photoUuid,
    this.designation = 'Staff',
    this.staffCode,
    this.isExpectedToday = true,
  });
}
