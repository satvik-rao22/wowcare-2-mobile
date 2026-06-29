/// Cards rendered on the parent/guardian dashboard, in default display order.
enum ParentDashboardCard {
  myChildsDay,
  studentAttendance,
  // studentBilling,
  studentNewsletters;

  String get title {
    switch (this) {
      case ParentDashboardCard.myChildsDay:
        return "My Child's Day";
      case ParentDashboardCard.studentAttendance:
        return "Student Attendance";
      case ParentDashboardCard.studentNewsletters:
        return "Student Newsletters";
    }
  }
}

class ParentDashboardViewModel {
  const ParentDashboardViewModel();

  static const double maxContentWidth = 640;

  static List<ParentDashboardCard> get defaultCards =>
      ParentDashboardCard.values;
}
