/// Cards rendered on the admin dashboard, declared in default display order.
enum AdminDashboardCard {
  myDay,
  enrollment,
  ratioMonitoring,
  classroomShifts,
  // events,
  // todo,
  availability,
  movements,
  billing;
  // classroomProgress,

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

class AdminDashboardViewModel {
  const AdminDashboardViewModel();

  static const double maxContentWidth = 640;

  static List<AdminDashboardCard> get defaultCards => AdminDashboardCard.values;
}
