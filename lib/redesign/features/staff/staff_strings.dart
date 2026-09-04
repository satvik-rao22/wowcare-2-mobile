import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/staff/models/staff_filters.dart';
import 'package:wowcare/redesign/features/staff/models/staff_member.dart';
import 'package:wowcare/redesign/features/staff/models/staff_role.dart';
import 'package:wowcare/redesign/features/staff/models/staff_status.dart';

/// Every word M06 Staff says. Shared vocabulary stays in `AppStrings`.
///
/// The app's words: Staff, a staff member (never Person, Adults, educator);
/// Sign In / Signed In / Signed Out / Not Marked; Sign-In PIN (never Kiosk
/// PIN or clock PIN); Guardian on a record; US spelling; no gendered pronouns.
abstract final class StaffStrings {
  // --- 6a roster ------------------------------------------------------------

  static const String title = 'Staff';
  static const String searchHint = 'Search staff';
  static const String activeStaff = 'Active staff';
  static const String startingSoon = 'Starting soon';
  static const String allDesignations = 'All designations';
  static const String aToZ = 'A to Z';
  static const String zToA = 'Z to A';
  static const String addStaff = 'Add Admin or Staff';

  static String staffMemberCount(int n) =>
      n == 1 ? '1 staff member' : '$n staff members';
  static String designationCount(int n) =>
      n == 1 ? '1 designation' : '$n designations';
  static String classroomCount(int n) =>
      n == 1 ? '1 classroom' : '$n classrooms';
  static String attendanceCount(int n) =>
      n == 1 ? '1 attendance status' : '$n attendance statuses';

  /// "Lead Teacher · Sunflower".
  static String designationScope(String designation, String scope) =>
      '$designation · $scope';

  /// What a row's sub-line says after the designation. An Admin covers the
  /// school by role, so their scope is every classroom; a cook, a floater and
  /// an office administrator are all legitimately without one.
  static String scopeOf(StaffMember member) {
    if (member.role == StaffRole.admin) return allClassrooms;
    return member.hasClassroom ? member.primaryClassroom : noClassroom;
  }

  /// A row's whole sub-line: "Lead Teacher · Sunflower".
  static String memberSubline(StaffMember member) =>
      designationScope(member.designation, scopeOf(member));

  static String allowedInChip(String classroom) => 'Allowed in $classroom';

  static String orderLabel(StaffOrder order) =>
      order == StaffOrder.aToZ ? aToZ : zToA;

  static const String loadingStaff = 'Loading staff…';

  static String upcomingSub(String designation, String scope) =>
      '$designation · $scope · upcoming';

  // Expanded row labels.
  static const String designation = 'Designation';
  static const String primaryClassroom = 'Primary classroom';
  static const String allowedIn = 'Allowed in';
  static const String today = 'Today';
  static const String breakLabel = 'Break';
  static const String phone = 'Phone';
  static const String email = 'Email';
  static const String noBreak = 'None';
  static const String noClassroom = 'No classroom';
  static const String allClassrooms = 'All classrooms';

  // Row keys.
  static const String call = 'Call';
  static String callName(String firstName) => 'Call $firstName';
  static const String moreActions = 'More actions';
  static const String openProfile = 'Open profile';
  static const String message = 'Message';

  // Select mode.
  static const String pickStaffToMessage = 'Pick staff to message';
  static String messageCount(int n) =>
      n == 1 ? 'Message 1 staff member' : 'Message $n staff members';

  // The More actions sheet.
  static const String signInForThem = 'Sign in for them';
  static const String signInForThemNote = 'Records who did it';
  static const String editWeekShifts = "Edit this week's shifts";
  static const String editWeekShiftsNote = 'Times and breaks';
  static const String changeClassrooms = 'Change classrooms';
  static const String changeClassroomsNote = 'Primary and allowed';
  static const String deactivate = 'Deactivate';
  static const String deactivateNote = 'Unfills their shifts';
  static const String reactivate = 'Reactivate';
  static const String reactivateNote =
      'Restores app access and the Sign-In PIN';

  // Roster states.
  static const String noMatchTitle = 'No staff match';
  static const String noMatchBody =
      'Try a different search, or clear the filters.';
  static const String noStaffTitle = 'No staff yet';
  static const String noStaffBody =
      'Add the first Admin or Staff member to get started.';

  // --- 6b filter ------------------------------------------------------------

  static const String filterTitle = 'Filter staff';
  static const String statusPickOne = 'Status · pick one';
  static const String primaryClassroomSection = 'Primary classroom';
  static const String allowedInSection = 'Allowed in';
  static const String classroomNote =
      'Primary is where a staff member is rostered. Allowed is every '
      'classroom they may cover.';
  static const String attendanceToday = 'Attendance today';
  static const String order = 'Order';

  /// "Active 7", or just "Active" when nothing counts.
  static String countedLabel(String label, int count) =>
      count == 0 ? label : '$label $count';

  static String statusLabel(StaffStatus status) => switch (status) {
    StaffStatus.active => 'Active',
    StaffStatus.upcoming => 'Upcoming',
    StaffStatus.inactive => 'Inactive',
  };

  static String roleLabel(StaffRole role) => switch (role) {
    StaffRole.admin => 'Admin',
    StaffRole.staff => 'Staff',
  };

  static String attendanceLabel(AttendanceStatus status) => switch (status) {
    AttendanceStatus.signedIn => 'Signed In',
    AttendanceStatus.signedOut => 'Signed Out',
    AttendanceStatus.absent => 'Absent',
    AttendanceStatus.notMarked => 'Not Marked',
  };

  // --- 6e when staff is not yours to see -----------------------------------

  static const String viewOnlyBanner =
      'You only have view access here. Contact your school if you need '
      'permission to add or change information.';
  static const String yourRecord = 'Your record';
  static String ownRecordSub(String designation, String scope, String pin) =>
      '$designation · $scope · PIN $pin';
  static const String open = 'Open';
  static const String ownRecordNote =
      'You can keep your own phone number, address and certificates up to '
      'date. Designation, classrooms and PIN are set by an Admin.';
  static String inYourClassrooms(int n) => 'In your classrooms · $n';
  static const String teamFootnote =
      'Just name, classroom and a way to call them.';

  static const String deniedBanner =
      'You do not have access to this area for your selected school.';
  static const String deniedTitle = 'Staff is closed for this school';
  static String deniedBody(String school) =>
      'Your account cannot open Staff at $school. Switch school, or ask an '
      'Admin there to give you access.';
  static const String switchSchool = 'Switch school';

  static String offlineBanner(String time) =>
      'No signal. This is the team as it was at $time.';
  static const String offlineTitle = 'Waiting for a signal';
  static const String offlineBody =
      'Names and classrooms are saved on this phone, so you can still see '
      'who is meant to be in today. Calling works; editing waits.';

  // --- 6c profile -----------------------------------------------------------

  static String attendanceLine(AttendanceStatus status, String time) =>
      switch (status) {
        AttendanceStatus.signedIn => 'signed in $time',
        AttendanceStatus.signedOut => 'signed out $time',
        AttendanceStatus.absent => 'absent today',
        AttendanceStatus.notMarked => 'not marked today',
      };

  static const String tabProfile = 'Profile';
  static const String tabSchedule = 'Schedule';
  static const String tabDates = 'Dates';
  static const String tabDocuments = 'Documents';

  static const String status = 'Status';
  static const String role = 'Role';
  static const String allowedClassrooms = 'Allowed classrooms';
  static const String signInPin = 'Sign-In PIN';
  static const String address = 'Address';
  static const String birthDate = 'Birth date';
  static const String jobTag = 'Job tag';
  static const String notRecorded = 'Not recorded';

  static String activeSince(String date) => 'Active since $date';
  static String startsOn(String date) => 'Starts $date';
  static String inactiveSince(String date) => 'Inactive since $date';
  static String birthDateWithAge(String date, int years) =>
      '$date ($years yrs)';

  static String whatCanChange(String firstName) => 'What $firstName can change';
  static const String whatCanChangeBody =
      'Phone, address and their own documents. Designation, role, classrooms '
      'and the Sign-In PIN are Admin-only, because they decide what they can '
      'do.';

  static const String thisWeek = 'This week';
  static String contracted(String hours) => '$hours contracted';
  static const String editTheWeek = 'Edit the week';
  static const String breaksTitle = 'Breaks come out of the ratio';
  static String breaksBody(String firstName, String time, String classroom) =>
      "$firstName's $time break is when $classroom needs cover.";
  static const String notScheduled = 'Not scheduled';
  static const String dayOff = 'Day off';
  static String shiftDetail(String scope, String breakLine) =>
      '$scope · $breakLine';
  static String breakRange(String start, String end) => 'break $start – $end';
  static const String noBreakSet = 'no break set';
  static const String dash = '—';

  static String attendanceSummary(int days, int absent, String hours) =>
      '$days days attended · $absent absent · $hours';
  static String signedInDetail(String time) => 'In $time · at the center';
  static String signedRange(String start, String end) => '$start – $end';
  static String absentDetail(String time) => 'Called in $time';
  static const String expectedToday = 'Expected today';

  static const String datesOnRecord = 'Dates on record';
  static const String datesOnRecordBody =
      'Hire date, CDA exam, background record check, first aid or CPR '
      'expiry, physical checkup.';
  static const String hireDate = 'Hire date';
  static const String cdaExam = 'CDA examination date';
  static const String backgroundCheck = 'Background record check';
  static const String firstAidExpiry = 'First aid / CPR expiration';
  static const String physicalCheckup = 'Physical checkup';

  static const String onFile = 'On file';
  static const String expired = 'Expired';
  static const String addDocument = 'Add a document';
  static const String documentsFootnote =
      'Staff can keep their own documents up to date when the center '
      'allows it.';
  static String documentDetail(String type, String date) => '$type · $date';
  static String documentExpires(String type, String date) =>
      '$type · expires $date';
  static const String kindPdf = 'PDF';
  static const String kindImage = 'IMG';

  // The add-document sheet (added: the frame draws the key, not the form).
  static const String documentName = 'Document name';
  static const String documentType = 'Document type';
  static const String expiryDate = 'Expiry date';
  static const String noExpiry = 'No expiry';
  static const String pickDocumentType = 'Pick a type';
  static const String addDocumentKey = 'Add document';
  static const String documentAdded = 'Document added';
  static const List<String> documentTypes = <String>[
    'Certificate',
    'Contract',
    'Identification',
    'Other',
  ];

  // --- 6d Add Admin or Staff -----------------------------------------------

  static const String step1Title = 'Name and contact';
  static const String step1Note = 'Name, email, phone';
  static const String step2Title = 'What they can do';
  static const String step2Note = 'Designation, role, classrooms';
  static const String step3Title = 'Their shifts';
  static const String step3Note = 'Times and breaks';
  static const String optional = 'Optional';
  static const String stepDone = '✓';

  static const String firstName = 'First name';
  static const String lastName = 'Last name';
  static const String workEmail = 'Work email';
  static const String workEmailHint =
      'The invitation goes here, and it becomes their sign-in.';
  static const String roleHint =
      'Admin can see every classroom, every student and the billing. Staff '
      'cannot.';
  static const String allowedHint =
      'Add a second classroom only if they will really cover it. Allowed '
      'classrooms widen what they can see.';
  static const String pickDesignation = 'Pick a designation';
  static const String pickClassroom = 'Pick a classroom';
  static const String pickClassrooms = 'Pick classrooms';
  static const String pickJobTags = 'Pick job tags';

  static const String sameShiftEveryDay = 'Same shift every day';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String shiftAndBreak = 'Shift and break';
  static const String copyToAllDays = 'Copy to all days';
  static const String shiftHint =
      'Work start, work end, then the lunch break start. A day can also be '
      'marked off.';
  static const String off = 'Off';
  static const String workStart = 'Work start';
  static const String workEnd = 'Work end';
  static const String breakStart = 'Break start';
  static const String markDayOff = 'Day off';
  static const String noBreakOption = 'No break';

  static const String nextWhatTheyCanDo = 'Next, what they can do';
  static const String nextTheirShifts = 'Next, their shifts';
  static String saveAndInvite(String firstName) =>
      firstName.isEmpty ? 'Save and invite' : 'Save and invite $firstName';
  static const String skipShifts = 'Skip, set the shifts later';
  static const String inviteNote =
      'This creates their record, their classrooms and their Sign-In PIN. It '
      'does not create a password, which still comes from the web.';
  static String added(String name) => '$name added';

  // Validation.
  static const String nameRequired = 'Enter a name';
  static const String invalidEmail = 'Enter a work email address';
  static const String invalidPhone = 'Enter a phone number';
  static const String pickDesignationError = 'Pick a designation';
  static const String pickPrimaryError = 'Pick a primary classroom';
  static const String pickAllowedError = 'Pick at least one allowed classroom';
  static const String shiftOrderError = 'Work start must be before work end.';
  static const String breakOutsideError =
      'A break must fall within the work hours.';

  // --- Edit -----------------------------------------------------------------

  static const String editTitle = 'Edit details';
  static const String saved = 'Saved';
  static const String street = 'Street';
  static const String addressLine2 = 'Address line 2';
  static const String city = 'City';
  static const String state = 'State';
  static const String zipCode = 'ZIP code';
  static const String adminOnlyNote =
      'Designation, role, classrooms and status are set by an Admin.';
  static const String contactSection = 'Name and contact';
  static const String addressSection = 'Address';
  static const String permissionsSection = 'What they can do';

  // --- Work schedule --------------------------------------------------------

  static const String scheduleTitle = 'Work schedule';
  static const String scheduleSaved = 'Schedule saved';
  static String scheduleFor(String firstName) => "$firstName's week";
  static const String saveSchedule = 'Save the week';
  static String weekTotal(String hours) => '$hours this week';

  /// A work schedule is Admin-only, per the module's own note on 13a.
  static const String scheduleDeniedTitle =
      'A work schedule is set by an Admin';
  static const String scheduleDeniedBody =
      'You can read your week on your own record. Ask an Admin at your school '
      'to change the hours or the breaks.';

  // --- States a screen can be in -------------------------------------------

  static const String couldNotReachTitle = 'Could not reach this record';
  static const String couldNotReachBody =
      'Nothing is saved on this phone for it yet. Try again once there is a '
      'signal.';
  static const String viewOnlyToast = 'You have view access here.';

  // --- 6f deactivate --------------------------------------------------------

  static String deactivateQuestion(String name) => 'Deactivate $name?';
  static String sinceLine(String designation, String scope, String date) =>
      '$designation · $scope · since $date';
  static const String whatChangesToday = 'What changes today';
  static const String losesStaff = 'Loses an assigned staff member';
  static String pinNumbered(String pin) => 'Sign-In PIN $pin';
  static const String stopsWorking = 'Stops working';
  static const String appAccess = 'App access';
  static const String ends = 'Ends';
  static const String keptOnFile = 'Kept on file';
  static const String keptItems = 'Hours, documents, history';
  static String deactivateWarning(String scope) =>
      "Check $scope's shifts before you do this. Nothing is deleted, and an "
      'inactive staff member can be reactivated.';
  static String deactivateKey(String firstName) => 'Deactivate $firstName';
  static const String keepActive = 'Keep them active';
  static String deactivated(String name) => '$name deactivated';
  static String reactivated(String name) => '$name reactivated';

  // --- Dates and times ------------------------------------------------------

  static const List<String> shortMonths = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> longMonths = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> shortWeekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// "12 Jan 2024".
  static String date(DateTime d) =>
      '${d.day} ${shortMonths[d.month - 1]} ${d.year}';

  /// "Thu 20 Aug".
  static String weekdayDate(DateTime d) =>
      '${shortWeekdays[d.weekday - 1]} ${d.day} ${shortMonths[d.month - 1]}';

  /// "THU", the schedule column's day.
  static String weekdayShort(int weekday) =>
      shortWeekdays[weekday - 1].toUpperCase();

  /// "Mon", a shift editor's row label.
  static String weekday(int weekday) => shortWeekdays[weekday - 1];

  /// "7:30", from minutes after midnight.
  static String clock(int minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// "8h 30m", from a number of minutes.
  static String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
