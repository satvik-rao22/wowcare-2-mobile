// ==================== MODEL ====================

import 'staff_model.dart';

class ClassroomSchedule {
  final String title;
  final String classroomCode;
  final String classroomName;
  final bool showWarning;
  final List<StaffModel> staffList;
  bool isExpanded;

  ClassroomSchedule({
    required this.title,
    required this.classroomCode,
    required this.classroomName,
    required this.showWarning,
    required this.staffList,
    this.isExpanded = false,
  });
}
