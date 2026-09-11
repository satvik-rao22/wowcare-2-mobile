/// Cards rendered on the staff dashboard, declared in default display order.
enum StaffDashboardCard {
  myDay,
  ratioMonitoring,
  myShifts,
  myAttendance;

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
