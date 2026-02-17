// Mock staff entity for UI-only implementation
class StaffEntity {
  final int id;
  final String name;
  final int primaryRoomId;
  final String? photoUuid;
  final String designation;

  StaffEntity({
    required this.id,
    required this.name,
    required this.primaryRoomId,
    this.photoUuid,
    this.designation = 'Staff',
  });
}
