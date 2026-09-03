/// Every word M03 Dashboard and More says.
///
/// Shared vocabulary (Students, Signed In, Logout, the nav slot names) stays
/// in `AppStrings`; this file holds only what the dashboards, More and Account
/// say themselves. Templated copy is a function so the sentence stays whole.
abstract final class DashboardStrings {
  // --- Header ---------------------------------------------------------------

  static String goodMorning(String firstName) => 'Good morning, $firstName';
  static String goodAfternoon(String firstName) => 'Good afternoon, $firstName';
  static String goodEvening(String firstName) => 'Good evening, $firstName';

  /// The guardian greeting, 3P1.
  static String hello(String firstName) => 'Hello, $firstName';

  /// "Maple View · Thu, 20 Aug".
  static String subline(String place, String date) => '$place · $date';

  // --- Attention deck (3A1) -------------------------------------------------

  static const String needsAttention = 'Needs your attention';
  static String deckCounter(int index, int total) => '$index of $total';

  static const String incidents = 'Incidents';
  static const String incidentsTitle = 'Awaiting your approval';
  static String reports(int n) => n == 1 ? 'report' : 'reports';
  static const String review = 'Review';

  static const String ratio = 'Ratio';
  static String ratioTitle(int n) => switch (n) {
    0 => 'Every classroom in ratio',
    1 => 'One classroom not in ratio',
    2 => 'Two classrooms not in ratio',
    _ => '$n classrooms not in ratio',
  };
  static String staffShort(int staff, int needed) =>
      '$staff staff · +$needed needed';

  static const String shifts = 'Shifts';
  static String shiftsTitle(String classroom, int needed) =>
      '$classroom needs $needed more staff';
  static String shiftWindow(String classroom, String window) =>
      '$classroom · $window';
  static String shiftNeeds(int needed, int scheduled) =>
      'Needs $needed staff, $scheduled scheduled';
  static const String scheduling = 'Scheduling';

  static const String movements = 'Movements';
  static const String movementsTitle = 'Classroom moves to action';
  static const String pending = 'Pending';
  static const String overdue = 'Overdue';

  static const String documents = 'Documents';
  static const String documentsTitle = 'Expiring & expired';
  static String expiredAndSoon(int expired, int soon) =>
      '$expired expired · $soon soon';
  static String soon(int n) => '$n soon';

  static const String thisMonth = 'This month';
  static const String totalOutstanding = 'Total outstanding';
  static String percent(int n) => '$n%';
  static const String openBilling = 'Open billing';

  // --- My day (3A1, 3S1) ----------------------------------------------------

  static const String myDay = 'My day';
  static const String since = 'Since';
  static const String workTime = 'Work time';
  static const String breakTime = 'Break';
  static const String signInPin = 'Sign-In PIN';
  static const String insideGeofence = 'Inside the school geofence';
  static const String outsideGeofence = 'Outside the school geofence';
  static const String transfer = 'Transfer';
  static const String markAbsent = 'Mark absent';
  static const String undoAbsent = 'Undo absence';
  static const String noSchedule = 'No shift today';

  static String signedInAt(String time) => 'Signed In at $time';
  static String signedOutAt(String time) => 'Signed Out at $time';
  static String transferredTo(String classroom) => 'Moved to $classroom';
  static const String markedAbsent = 'Marked absent for today';
  static const String absenceUndone = 'Absence undone';

  static const String transferTitle = 'Transfer to';
  static const String transferSubtitle = 'Pick the classroom you are moving to';
  static const String markAbsentTitle = 'Mark yourself absent?';
  static const String markAbsentBody =
      'Today is recorded as an absence. It can be undone all day.';

  // --- Confirm sign out (3A3, 3S3, 3P3) -------------------------------------

  static String signOutPerson(String name) => 'Sign Out $name?';
  static String signedInAtOnClock(String time, String onClock) =>
      'Signed In at $time · $onClock on the clock';
  static const String signOutTime = 'Sign Out time';
  static const String edited = 'Edited';
  static const String now = 'Now';
  static const String auditNote =
      'Any adjustment is logged against your name for the audit trail.';
  static const String confirmSignOut = 'Confirm sign out';

  static const String signOutForDay = 'Sign Out for the day?';
  static const String signOutForDayBody =
      'This closes your shift and stops your hours.';
  static const String totalToday = 'Total today';
  static const String classroom = 'Classroom';
  static String dropsToOneStaff(String classroom) =>
      '$classroom drops to one staff member when you leave. '
      'An Admin has been notified.';
  static const String onlyAdminAdjusts =
      'Wrong time? Only an Admin or Director can adjust a recorded sign out.';
  static const String yesSignMeOut = 'Yes, sign me out';
  static const String staySignedIn = 'Stay signed in';

  static String classroomToldLeaving(String classroom, String child) =>
      '$classroom will be told $child is leaving with you.';
  static const String by = 'By';
  static String classroomToldLeft(String classroom, String child) =>
      '$classroom is told $child has left with you, and the record keeps '
      'your name against the time.';
  static const String notYet = 'Not yet';

  static const String adjustEarlier = 'Five minutes earlier';
  static const String adjustLater = 'Five minutes later';

  // --- Today's school status (3A1) ------------------------------------------

  static const String schoolStatus = "Today's school status";
  static const String classrooms = 'Classrooms';
  static const String capacity = 'Capacity';
  static const String fullTimeEquivalent = 'Full time equivalent';
  static String enrolledExpected(int enrolled, int expected) =>
      '$enrolled enrolled · $expected expected';
  static String expectedToday(int n) => '$n expected today';

  // --- Ratio monitoring (3A2, 3S1) ------------------------------------------

  static const String ratioMonitoring = 'Ratio monitoring';
  static String notInRatioCount(int n) => '$n not in ratio';
  static const String allInRatio = 'All in ratio';
  static String studentsAndStaff(int students, int staff) =>
      '$students students · $staff staff';
  static String plusStaff(int n) => '+$n staff';
  static const String myClassrooms = 'My classrooms';
  static String ofIn(int total) => 'of $total in';
  static String classroomAndGroup(String classroom, String group) =>
      '$classroom · $group';
  static String covering(String classroom, String from) =>
      '$classroom · covering $from';
  static String coveringNoTime(String classroom) => '$classroom · covering';

  // --- Classroom shifts (3A2) -----------------------------------------------

  static const String classroomShifts = 'Classroom shifts';
  static const String today = 'Today';
  static const String filled = 'Filled';
  static const String open = 'Open';
  static String shiftFilledLine(String window, String staff) =>
      '$window · $staff';
  static String shiftOpenLine(String window, int needed, int scheduled) =>
      '$window · needs $needed, $scheduled scheduled';
  static const String noShiftsToday = 'No shifts scheduled today';

  // --- Availability and movements (3A2) -------------------------------------

  static String placesFilled(int capacity) => 'of $capacity places filled';
  static const String movesToApprove = 'moves to approve';

  // --- Billing (3A2) --------------------------------------------------------

  static const String billing = 'Billing';
  static const String invoiced = 'Invoiced';
  static const String netPaid = 'Net paid';
  static const String inProcess = 'In process';
  static const String outstanding = 'Outstanding';
  static const String allUnpaidToDate = 'All unpaid to date';
  static const String allUnpaidSub = 'Every open invoice, not just this range';
  static const String billingRangeTitle = 'Billing range';

  // --- My shifts and my attendance (3S2) ------------------------------------

  static const String myShifts = 'My shifts';
  static String shiftLine(String window, String breakWindow) =>
      '$window · break $breakWindow';
  static const String dayOff = 'Day off';
  static const String myAttendance = 'My attendance';
  static const String change = 'Change';
  static const String daysAttended = 'Days attended';
  static const String hoursAttended = 'Hours attended';
  static String daysAbsent(int n) => n == 1 ? 'Day absent' : 'Days absent';
  static String hoursMinutes(int hours, int minutes) => '${hours}h ${minutes}m';
  static String hoursOnly(int hours) => '${hours}h';
  static String arrow(String from, String to) => '$from → $to';
  static const String attendanceRangeTitle = 'Attendance range';

  // --- Guardian (3P1, 3P2) --------------------------------------------------

  static const String yourStudents = 'Your students';
  static String childAndRoom(String first, String classroom) =>
      '$first · $classroom';
  static String roomAndAge(String classroom, String age) => '$classroom · $age';
  static const String dayEnds = 'Day ends';
  static const String reminder = 'Reminder';
  static const String reminderSub = 'Tell me before the school day ends';
  static String childActivities(String first) => "$first's activities";
  static const String seeAll = 'See all';
  static const String nap = 'Nap';
  static const String meals = 'Meals';
  static const String photos = 'Photos';
  static const String bathroom = 'Bathroom';
  static String startedAt(String time) => 'Started $time';
  static String logged(int n) => '$n logged';
  static String todayCount(int n) => '$n today';
  static const String noActivitiesYet = 'Nothing logged yet today';

  static const String attendance = 'Attendance';
  static const String daysPresent = 'Days present';
  static String absentReason(String reason) => 'Absent · $reason';

  static const String balanceDue = 'Balance due';
  static String dueOn(String date) => 'Due $date';
  static String tuitionAutopay(String month, {required bool autopayOn}) =>
      autopayOn ? '$month tuition · autopay is on' : '$month tuition';
  static const String payNow = 'Pay now';
  static const String nothingDue = 'Nothing due';
  static const String invoices = 'Invoices';
  static const String all = 'All';
  static String paidWith(String date, String method) => 'Paid $date · $method';
  static String newsletterMeta(String classroom, String when) =>
      '$classroom · $when';
  static const String noNewsletters = 'No newsletters yet';
  static const String noChildren = 'No students on this account';
  static const String noChildrenSub =
      'Ask your school to link your students to this account.';

  // --- More (3M) ------------------------------------------------------------

  static const String studentsGroup = 'Students';
  static const String staffGroup = 'Staff';
  static const String centerGroup = 'Center';
  static const String availability = 'Availability';
  static const String events = 'Events';
  static const String tasks = 'Tasks';
  static const String newsletter = 'Newsletter';
  static const String reportsTile = 'Reports';
  static const String settings = 'Settings';
  static String designationAt(String designation, String place) =>
      '$designation · $place';

  // --- Account (3M2, 13d) ---------------------------------------------------

  static const String account = 'Account';
  static const String profileGroup = 'Profile';
  static const String accessGroup = 'Access';
  static const String supportGroup = 'Support';
  static const String myProfile = 'My Profile';
  static const String myProfileSub = 'Name, email, address';
  static const String notificationSettings = 'Notification Settings';
  static String groups(int n) => n == 1 ? '1 group' : '$n groups';
  static const String switchProfile = 'Switch Profile';
  static String rolesHere(int n) => n == 1 ? '1 role here' : '$n roles here';
  static const String switchSchool = 'Switch school';
  static const String switchOrganization = 'Switch Organization';
  static const String changePassword = 'Change Password';
  static const String help = 'Help';
  static const String helpHost = 'help.childcarewow.com ↗';
  static const String helpUrl = 'https://help.childcarewow.com';
  static const String kioskMode = 'Kiosk mode';
  static const String kioskModeSub = 'Lock this device to the sign-in door';
  static const String helpUnavailable = 'Could not open the help center';

  static String switchProfileBody(int roles, String school) =>
      'This account holds ${_words(roles)} roles at $school. Switching '
      'changes what the app shows you — same person, different tools.';
  static const String switchProfileNote =
      "Switching takes you to that role's dashboard fresh. Nothing is "
      'signed out.';
  static const String personaAdmin = 'Admin';
  static const String personaAdminSub = 'Every classroom, billing, reports';
  static const String personaAdminMark = 'ADM';
  static const String personaStaff = 'Staff';
  static const String personaStaffSub = 'Your classrooms and your day';
  static const String personaStaffMark = 'STF';
  static const String personaParent = 'Parent';
  static String personaParentSub(List<String> firstNames) => switch (firstNames
      .length) {
    0 => "Just your students' day",
    1 => "Just ${firstNames.first}'s day",
    _ =>
      'Just ${firstNames.sublist(0, firstNames.length - 1).join(', ')} '
          "and ${firstNames.last}'s day",
  };
  static const String personaParentMark = 'PAR';
  static String nowViewingAs(String persona) => 'Now viewing as $persona';

  static const String switchSchoolTitle = 'Switch school';
  static const String switchSchoolSubtitle = 'Schools you can open here';
  static const String switchOrganizationTitle = 'Switch Organization';
  static const String switchOrganizationSubtitle = 'Organizations on this account';
  static String yourRole(String role) => 'Your role here: $role';
  static String nowViewing(String place) => 'Now viewing $place';

  static const String changePasswordBody =
      'Are you sure you want to change your password? A password reset link '
      'will be sent to your registered email.';
  static const String yesChangePassword = 'Yes, Change Password';
  static String resetLinkSent(String email) => 'Reset link sent to $email';
  static const String resetLinkFailed =
      'Could not send the reset link. Try again.';

  static const String logoutTitle = 'Logout of WowCare?';
  static const String logoutBody =
      'You will need your email and password to get back in. Accounts are '
      'created by your school, so logging out never removes anything.';
  static const String logoutStopsTitle = 'What stops on this phone';
  static const String logoutStopsBody =
      'Push notifications for this device · your cached classrooms · your '
      'sign-in PIN reminder';

  static String _words(int n) => switch (n) {
    1 => 'one',
    2 => 'two',
    3 => 'three',
    _ => '$n',
  };
}
