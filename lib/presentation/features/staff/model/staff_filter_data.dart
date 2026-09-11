enum StaffFilterSection {
  /// Uses the "Allowed Classroom" list as the classroom multi-select.
  classroom,
  designation,
  status,
  sortBy,
  attendanceStatus,

  /// Legacy: show the old Primary Classroom dropdown.
  primaryClassroom,

  /// Legacy: show the old Allowed Classroom dropdown.
  allowedClassroom,
}

class FilterData {
  final List<int> classroomIds;
  final List<String> classrooms;

  /// Selected primary classroom names (for Primary Classroom dropdown).
  final List<String>? primaryClassrooms;

  /// Selected allowed classroom names (for Allowed Classroom dropdown).
  final List<String>? allowedClassrooms;
  final List<String> statuses;
  final List<String> tags;
  final List<String> attendanceStatuses;

  /// Sort direction: 'asc' or 'desc'.
  final String? sortBy;

  FilterData({
    required this.classroomIds,
    required this.classrooms,
    this.primaryClassrooms,
    this.allowedClassrooms,
    required this.statuses,
    required this.tags,
    this.attendanceStatuses = const [],
    this.sortBy,
  });

  static FilterData createWithTagMapping({
    required List<int> classroomIds,
    required List<String> classrooms,
    required List<String> statuses,
    required List<String> tags,
    List<String> attendanceStatuses = const [],
  }) {
    return FilterData(
      classroomIds: classroomIds,
      classrooms: classrooms,
      statuses: statuses,
      tags: tags,
      attendanceStatuses: attendanceStatuses,
    );
  }
}
