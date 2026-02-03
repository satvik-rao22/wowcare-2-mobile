class Classroom {
  const Classroom({
    required this.code,
    required this.name,
    this.capacity,
    required this.type,
    required this.status,
  });

  final String code;
  final String name;
  final int? capacity;
  final String type;
  final String status;
}

class ClassroomPage {
  const ClassroomPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<Classroom> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;
}


