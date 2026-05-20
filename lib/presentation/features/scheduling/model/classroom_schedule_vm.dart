import 'staff_schedule_staff_vm.dart';

class ClassroomScheduleVm {
  final String title;
  final String classroomCode;
  final String classroomName;
  final bool showWarning;
  final List<StaffScheduleStaffVm> staffList;
  bool isExpanded;

  ClassroomScheduleVm({
    required this.title,
    required this.classroomCode,
    required this.classroomName,
    required this.showWarning,
    required this.staffList,
    this.isExpanded = false,
  });
}
