class Tag {
  final int id;
  final String name;

  const Tag({required this.id, required this.name});
}

class Student {
  final int id;
  final String fullName;
  final String? photoUuid;
  final String? roomName;
  final int? roomId;
  final List<Tag> tags;

  const Student({
    required this.id,
    required this.fullName,
    this.photoUuid,
    this.roomName,
    this.roomId,
    required this.tags,
  });
}
