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

  /// Matches [StudentEntity]: same [staffCode] is the same person in sets/lists
  /// even when the list is rebuilt after search/filter.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StaffEntity) return false;
    final a = (staffCode ?? '').trim();
    final b = (other.staffCode ?? '').trim();
    if (a.isNotEmpty && b.isNotEmpty) return a == b;
    return id == other.id && name == other.name;
  }

  @override
  int get hashCode {
    final c = (staffCode ?? '').trim();
    if (c.isNotEmpty) return c.hashCode;
    return Object.hash(id, name);
  }
}
