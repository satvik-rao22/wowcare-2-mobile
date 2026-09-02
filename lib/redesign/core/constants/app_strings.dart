/// Every word the app says, grouped by module.
///
/// No copy is written inline in a widget. Templated copy is a function, so the
/// sentence stays in one piece rather than being assembled at the call site.
///
/// **The app's own words win**, and these are not interchangeable:
/// * **Students**, never children or kids.
/// * **Sign In / Signed In / Signed Out / Not Marked** for attendance.
/// * **Logout** means leaving the app. It is never swapped with Sign Out,
///   which is a student leaving for the day.
/// * **Dashboard**, never Home. **Classrooms**, never Rooms.
/// * US spelling, and no gendered pronouns anywhere.
library;

/// Words shared across modules.
abstract final class AppStrings {
  static const String appName = 'WowCare';

  // --- The five nav slots, and More ----------------------------------------

  static const String dashboard = 'Dashboard';
  static const String attendance = 'Attendance';
  static const String classrooms = 'Classrooms';
  static const String activities = 'Activities';
  static const String messages = 'Messages';
  static const String billing = 'Billing';
  static const String more = 'More';

  // --- Verbs on a key -------------------------------------------------------

  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String done = 'Done';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String close = 'Close';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String remove = 'Remove';
  static const String confirm = 'Confirm';
  static const String apply = 'Apply';
  static const String clear = 'Clear';
  static const String retry = 'Try again';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String select = 'Select';
  static const String selectAll = 'Select all';
  static const String viewAll = 'View all';

  /// Leaving the app. Never used for a student leaving for the day.
  static const String logout = 'Logout';

  // --- Attendance vocabulary, shared by every module that shows a status ---

  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  static const String signedIn = 'Signed In';
  static const String signedOut = 'Signed Out';
  static const String absent = 'Absent';
  static const String notMarked = 'Not Marked';
  static const String inRatio = 'In Ratio';
  static const String notInRatio = 'Not in Ratio';

  // --- People ---------------------------------------------------------------

  static const String student = 'Student';
  static const String students = 'Students';
  static const String staff = 'Staff';
  static const String guardian = 'Guardian';
  static const String guardians = 'Guardians';

  /// Ratio is written students first, and has two states only.
  static String ratio(int students, int staff) => '$students:$staff';

  static String studentCount(int n) => n == 1 ? '1 student' : '$n students';
  static String staffCount(int n) => n == 1 ? '1 staff' : '$n staff';

  // --- States a screen can be in -------------------------------------------

  static const String loading = 'Loading…';
  static const String somethingWentWrong = 'Something went wrong';
  static const String noConnection = 'No connection';
  static const String checkConnection =
      'Check your connection and try again.';

  // --- Required fields ------------------------------------------------------

  static const String requiredField = 'This field is required';

  /// The asterisk beside a required field's label, drawn in pink.
  static const String requiredMark = '*';
}
