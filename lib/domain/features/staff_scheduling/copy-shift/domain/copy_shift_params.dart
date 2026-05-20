class CopyShiftParams {
  final String schoolCode;
  final String organizationCode;
  final String classroomCode;
  final String sourceWeekStart;
  final String targetWeekStart;

  CopyShiftParams({
    required this.schoolCode,
    required this.organizationCode,
    required this.classroomCode,
    required this.sourceWeekStart,
    required this.targetWeekStart,
  });

  Map<String, dynamic> toJson() {
    return {
      "schoolCode": schoolCode,
      "organizationCode": organizationCode,
      "classroomCode": classroomCode,
      "sourceWeekStart": sourceWeekStart,
      "targetWeekStart": targetWeekStart,
    };
  }
}
