/// Every path in the redesign, in one place.
///
/// The existing router spreads paths across an `AppRoutes` class and 104
/// scattered `Screen.routeName` statics; this file is the whole inventory and
/// nothing else declares a path. Navigation calls `context.go` / `context.push`
/// with one of these, or with one of the templated functions for a record.
///
/// Shape: six shell branches mirror the tab bar's slots (Billing is a slot for
/// guardians only). A module reached from More lives **under the dashboard
/// branch**, so back returns to the dashboard and no tab lights up, which is
/// the app's own `_syncSelectedItemFromRoute` rule. Forms, wizards and sheets
/// that hide the tab bar are pushed on the root navigator.
abstract final class AppRoutes {
  // --- M01 Authentication, outside the shell -------------------------------

  static const String signIn = '/sign-in';
  static const String chooseOrganization = '/sign-in/organization';
  static const String chooseSchool = '/sign-in/school';
  static const String forgotPassword = '/forgot-password';
  static const String checkEmail = '/forgot-password/sent';
  static const String resetPassword = '/reset-password';

  // --- M01 Kiosk, outside the shell (lockdown: no tab bar, no back) --------

  static const String kiosk = '/kiosk';
  static const String kioskScanner = '/kiosk/scan';

  /// Asked before the picker when a family is half in and half out (2d).
  static const String kioskChoice = '/kiosk/choice';
  static const String kioskFamily = '/kiosk/family';

  // --- Shell branch roots (the five slots, plus Billing for guardians) ------

  static const String dashboard = '/dashboard';
  static const String attendance = '/attendance';
  static const String classrooms = '/classrooms';
  static const String activities = '/activities';
  static const String messages = '/messages';
  static const String billing = '/billing';

  // --- M03 Dashboard and More ----------------------------------------------

  static const String more = '$dashboard/more';
  static const String account = '$dashboard/more/account';
  static const String scanQr = '$dashboard/scan';

  // --- M12 Notifications ---------------------------------------------------

  static const String notifications = '$dashboard/notifications';

  // --- M13 My Profile ------------------------------------------------------

  static const String profile = '$dashboard/profile';
  static const String editProfile = '$dashboard/profile/edit';
  static const String notificationSettings =
      '$dashboard/profile/notification-settings';
  static const String changePassword = '$dashboard/profile/change-password';

  // --- M05 Students --------------------------------------------------------

  static const String students = '$dashboard/students';
  static const String addStudent = '$dashboard/students/new';
  static String student(String id) => '$dashboard/students/$id';
  static String editStudent(String id) => '$dashboard/students/$id/edit';

  // --- M06 Staff -----------------------------------------------------------

  static const String staff = '$dashboard/staff';
  static const String addStaff = '$dashboard/staff/new';
  static String staffMember(String id) => '$dashboard/staff/$id';
  static String editStaffMember(String id) => '$dashboard/staff/$id/edit';
  static String staffSchedule(String id) => '$dashboard/staff/$id/schedule';

  // --- M07 Classrooms (its own branch) -------------------------------------

  static const String addClassroom = '$classrooms/new';
  static String classroom(String id) => '$classrooms/$id';
  static String classroomProfile(String id) => '$classrooms/$id/profile';
  static String assignStudents(String id) => '$classrooms/$id/assign-students';
  static String assignStaff(String id) => '$classrooms/$id/assign-staff';

  // --- M04 Attendance (its own branch) -------------------------------------

  static const String attendanceSignIn = '$attendance/sign-in';
  static const String attendanceRange = '$attendance/range';

  // --- M08 Activities (its own branch) -------------------------------------

  static const String activityApprovals = '$activities/approvals';
  static const String newActivity = '$activities/new';
  static const String chooseActivity = '$activities/new/type';
  static String activityForm(String type) => '$activities/new/$type';
  static String activity(String id) => '$activities/$id';

  // --- M09 Communication (its own branch) ----------------------------------

  static const String newMessage = '$messages/new';
  static const String composeMessage = '$messages/new/compose';
  static const String staffDirectory = '$messages/staff-directory';
  static String conversation(String id) => '$messages/$id';

  // --- M10 Billing (its own branch; admin and guardian share the root) -----

  static const String transactions = '$billing/transactions';
  static const String newInvoice = '$billing/invoice/new';
  static const String newInvoiceDetails = '$billing/invoice/new/details';
  static const String newInvoicePreview = '$billing/invoice/new/preview';
  static const String receivePayment = '$billing/payment';
  static const String issueRefund = '$billing/refund';
  static const String addCredit = '$billing/credit';
  static String family(String id) => '$billing/family/$id';
  static const String statements = '$billing/statements';
  static const String generateStatement = '$billing/statements/new';
  static const String ledger = '$billing/ledger';
  static const String newLedgerAccount = '$billing/ledger/new';
  static String ledgerAccount(String id) => '$billing/ledger/$id';
  static const String analytics = '$billing/analytics';
  static const String discounts = '$billing/discounts';
  static const String newDiscount = '$billing/discounts/new';
  static String discount(String id) => '$billing/discounts/$id';
  static String invoice(String id) => '$billing/invoice/$id';
  static String receipt(String id) => '$billing/receipt/$id';
  static const String payNow = '$billing/pay-now';
  static const String payNowAuthorize = '$billing/pay-now/authorize';
  static const String autoPay = '$billing/auto-pay';
  static const String autoPayNewMethod = '$billing/auto-pay/new';

  // --- M11 Movements and Availability --------------------------------------

  static const String movements = '$dashboard/movements';
  static const String confirmMovement = '$dashboard/movements/confirm';
  static const String newMovement = '$dashboard/movements/new';
  static String editMovement(String id) => '$dashboard/movements/$id/edit';
  static const String availability = '$dashboard/availability';

  // --- M14 Scheduling ------------------------------------------------------

  static const String scheduling = '$dashboard/scheduling';
  static const String newShift = '$dashboard/scheduling/new';
  static String shift(String id) => '$dashboard/scheduling/$id';
  static const String publishSchedule = '$dashboard/scheduling/publish';

  // --- M15 Newsletter ------------------------------------------------------

  static const String newsletters = '$dashboard/newsletters';
  static String newsletter(String id) => '$dashboard/newsletters/$id';

  // --- M16 Reports ---------------------------------------------------------

  static const String reports = '$dashboard/reports';
  static String reportForm(String type) => '$dashboard/reports/$type';
  static String reportViewer(String id) => '$dashboard/reports/view/$id';

  // --- M17 Events, Tasks and Calendar --------------------------------------

  static const String events = '$dashboard/events';
  static const String newEvent = '$dashboard/events/new';
  static String event(String id) => '$dashboard/events/$id';
  static String editEvent(String id) => '$dashboard/events/$id/edit';
  static const String holidays = '$dashboard/events/holidays';
  static const String tasks = '$dashboard/tasks';
  static const String newTask = '$dashboard/tasks/new';
  static String task(String id) => '$dashboard/tasks/$id';
  static String editTask(String id) => '$dashboard/tasks/$id/edit';
}
