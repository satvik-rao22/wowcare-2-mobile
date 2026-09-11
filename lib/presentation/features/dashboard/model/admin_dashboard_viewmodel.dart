/// Cards rendered on the admin dashboard, declared in default display order.
enum AdminDashboardCard {
  myDay,
  enrollment,
  ratioMonitoring,
  classroomShifts,
  availability,
  movements,
  billing;

  String get title {
    switch (this) {
      case AdminDashboardCard.myDay:
        return 'My Day';
      case AdminDashboardCard.enrollment:
        return 'Enrollment';
      case AdminDashboardCard.ratioMonitoring:
        return 'Ratio Monitoring';
      case AdminDashboardCard.classroomShifts:
        return 'Classroom Shifts';
      case AdminDashboardCard.availability:
        return 'Future Availability';
      case AdminDashboardCard.movements:
        return 'Individual Movements';
      case AdminDashboardCard.billing:
        return 'Billing';
    }
  }
}
