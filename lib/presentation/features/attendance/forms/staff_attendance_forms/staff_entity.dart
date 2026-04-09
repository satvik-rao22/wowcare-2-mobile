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

  StaffEntity({
    required this.id,
    required this.name,
    required this.primaryRoomId,
    this.classroomCode,
    this.classroomName,
    this.photoUuid,
    this.designation = 'Staff',
    this.staffCode,
  });
}
