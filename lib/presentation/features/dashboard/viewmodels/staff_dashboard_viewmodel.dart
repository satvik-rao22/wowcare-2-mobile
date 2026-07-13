/// Cards rendered on the staff dashboard, declared in default display order.
enum StaffDashboardCard {
  myDay,
  ratioMonitoring,
  // events,
  // todo,
  myShifts,
  myAttendance;
  // classroomProgress,

  String get title {
    switch (this) {
      case StaffDashboardCard.myDay:
        return 'My Day';
      case StaffDashboardCard.ratioMonitoring:
        return 'Ratio Monitoring';
      case StaffDashboardCard.myShifts:
        return 'My Shifts';
      case StaffDashboardCard.myAttendance:
        return 'My Attendance';
    }
  }
}

class StaffDashboardViewModel {
  const StaffDashboardViewModel();

  static const double maxContentWidth = 640;

  static List<StaffDashboardCard> get defaultCards => StaffDashboardCard.values;
}
