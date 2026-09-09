/// Wire model for the per-classroom attendance summary APIs
/// (by-classrooms student/staff summary cards). Mapped to
/// `ClassroomAttendanceSummaryEntry` via `ClassroomMapper`.
class ClassroomAttendanceSummaryDataModel {
  const ClassroomAttendanceSummaryDataModel({
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

  factory ClassroomAttendanceSummaryDataModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClassroomAttendanceSummaryDataModel(
      expected: json['expected'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      signout: json['signout'] as int? ?? 0,
      notMarked: json['notMarked'] as int? ?? 0,
    );
  }
}
