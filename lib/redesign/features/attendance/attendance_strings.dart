/// Every word M04 Attendance says. Shared vocabulary (Sign In, Signed In,
/// Sign Out, Signed Out, Not Marked, Absent, In Ratio, Clear all, Try again…)
/// stays in `AppStrings`.
///
/// The verbs here are load-bearing and are not interchangeable: **Sign In /
/// Signed In / Sign Out / Signed Out / Not Marked / Absent / Mark Absent /
/// Transfer / Override Sign In**. Never "check in" or "check out", and never
/// "clock in": a staff member signs in exactly the way a student does, which
/// is why the two lists read the same. No gendered pronouns anywhere.
abstract final class AttendanceStrings {
  // --- 4a Live --------------------------------------------------------------

  static String guardianTitle(String firstName) => "$firstName's attendance";
  static const String selectTitle = 'Select students';
  static String selectedTitle(int n) => n == 1 ? '1 selected' : '$n selected';

  static const String selectKey = 'Select';
  static const String doneKey = 'Done';
  static const String searchKey = 'Search attendance';
  static const String searchHint = 'Search a name';
  static const String signInKey = 'Sign students in';

  static const String studentsSegment = 'Students';
  static const String staffSegment = 'Staff';
  static String inOfCount(int inCount, int total) => '$inCount of $total in';
  static String inRangeCount(int n) => '$n in the range';

  /// The chip run over the list.
  static const String allChip = 'All';

  // --- Row and its open record ---------------------------------------------

  static String pillSignedIn(String time) => 'In $time';
  static String pillSignedOut(String time) => 'Out $time';
  static String pillDue(String time) => 'Due $time';

  /// "8:42 · PIN", the value the open record puts against Signed In.
  static String timeAndMethod(String time, String method) => '$time · $method';

  static String rowSignedIn(String scope, String time, String method) =>
      '$scope · in $time · $method';
  static String rowSignedOut(String scope, String inTime, String outTime) =>
      '$scope · in $inTime, out $outTime';
  static String rowExpected(String scope) => '$scope · expected today';
  static String rowNotExpected(String scope) => '$scope · not expected today';

  static const String detailSignedIn = 'Signed In';
  static const String detailSignedOut = 'Signed Out';
  static const String detailBy = 'By';
  static const String detailClassroom = 'Classroom';
  static const String detailRole = 'Role';
  static const String detailExpected = 'Expected';
  static const String detailDuration = 'Duration';
  static const String detailReason = 'Reason';
  static const String detailTransfer = 'Transfer';
  static const String detailNextAction = 'Next action';
  static const String detailTransferredBy = 'Transferred by';
  static const String detailNotRecorded = '—';
  static const String detailMarkedAbsent = 'Marked Absent';

  /// `isExpectedToday`, which is the honest replacement for an arrival time
  /// the API does not hold.
  static const String expectedToday = 'Today';
  static const String expectedNotToday = 'Not today';

  static const String moreActionsKey = 'More actions';

  /// `Sunflower to Bluebell · 2 of 3`.
  static String transferPath(String from, String to) => '$from to $to';
  static String transferSequence(int step, int total) => '$step of $total';
  static String transferBy(String name, String reason) => '$name · $reason';

  // --- Groups ---------------------------------------------------------------

  static const String onShiftEyebrow = 'On shift today';
  static String groupMeta({
    required int signedIn,
    required int enrolled,
    required int staffPresent,
    required String verdict,
  }) => '$signedIn of $enrolled in · ${_staff(staffPresent)} · $verdict';
  static String staffGroupMeta(int signedIn, int total) =>
      '$signedIn of $total signed in';

  static String _staff(int n) => n == 1 ? '1 staff' : '$n staff';

  static const String noStaffInRoom = 'no staff in the classroom';
  static String staffShort(int n) =>
      n == 1 ? '1 more needed' : '$n more needed';

  // --- Scope note -----------------------------------------------------------

  static const String scopeStaffTitle = 'Your classroom only';
  static String scopeStaffBody(String classroom) =>
      '$classroom is the classroom you are rostered in today. '
      'Cross-classroom sign in is a school setting your center keeps off.';
  static String scopeAdminTitle(int shown, int total) =>
      'Showing $shown of $total classrooms';
  static String scopeAdminBody(int students) =>
      '$students students across the classrooms on screen. '
      'Clear the filter to see every classroom.';
  static const String hoursTodayTitle = 'Hours so far today';
  static String hoursTodayBody(String total, int people) =>
      '$total across ${_people(people)} on the clock right now.';

  static String _people(int n) => n == 1 ? '1 person' : '$n people';

  // --- 4a select mode -------------------------------------------------------

  static const String pickWhoArrived = 'Pick who arrived';
  static String signInCount(int n) =>
      n == 1 ? 'Sign In 1 student' : 'Sign In $n students';
  static String signInStaffCount(int n) =>
      n == 1 ? 'Sign In 1 staff' : 'Sign In $n staff';

  // --- 4a record sheet ------------------------------------------------------

  static const String overrideSignIn = 'Override Sign In';
  static const String signBackIn = 'Sign back in';
  static const String markAbsent = 'Mark Absent';
  static const String undoAbsence = 'Undo absence';
  static const String transfer = 'Transfer';
  static const String editTimes = 'Edit times';
  static const String openProfile = 'Open profile';

  /// A sheet's sub-line: where they are, and whether they were due at all.
  static String sheetScope(String scope, {required bool isExpected}) =>
      isExpected ? scope : '$scope · not expected today';

  static String noteSignedIn(String time) => 'Signed In $time';
  static String noteSignedInBody(String by, String method, String span) =>
      'By $by on the $method. Here $span so far.';
  static String noteSignedOut(String time) => 'Signed Out $time';
  static String noteSignedOutBody(String by, String method, String span) =>
      'By $by on the $method. Here $span today.';
  static const String noteNotMarked = 'Not Marked';
  static const String noteNotMarkedBody =
      'Expected today, and nothing recorded yet. '
      'Message the family from here.';
  static const String noteNotExpectedBody =
      'Not expected today, and nothing recorded yet. '
      'Signing in anyway is recorded as an override.';
  static const String noteAbsent = 'Absent';
  static String noteAbsentBody(String reason) =>
      '$reason. Signing in overrides the absence and tells the classroom lead.';

  static const String footerSignedIn =
      'Mark Absent is off once someone is here. Editing a time leaves an '
      'audit note with your name on it.';
  static const String footerNotMarked =
      'Nothing to edit until a time is recorded.';
  static const String footerAbsent =
      'Override Sign In is an Admin action and is recorded as one.';
  static const String footerSignedOut =
      'A second sign in on the same day makes a second row, it does not '
      'overwrite the first.';

  // --- 4b Pick a day, or a range -------------------------------------------

  static const String whichDay = 'Which day?';
  static const String todayOption = 'Today';
  static const String yesterdayOption = 'Yesterday';
  static const String pickADayOption = 'Pick a day';
  static const String rangeOption = 'A range of days';

  static String todaySub(String date) => '$date · live, actions on';
  static String yesterdaySub(String date) => '$date · a past day, read only';
  static const String pickADaySub = 'Calendar, back to enrollment';
  static const String rangeSub = 'Attended days and attended time';
  static const String rangeTo = 'to';
  static const String showThisDay = 'Show this day';
  static const String showThisRange = 'Show this range';
  static String pickedDaySub(String date) => '$date · a past day, read only';
  static const String dayFooter =
      'A past day opens read only, with Edit times still available to '
      'Admins. Ranges show totals and hours instead of sign in buttons.';
  static const String readOnlyDay =
      'A past day is read only. Edit times is still open to Admins.';

  // --- 4c Staff, and cover for a gap ---------------------------------------

  static String gapTitle(String classroom, String time) =>
      '$classroom needs 1 more staff at $time';
  static const String openScheduling = 'Open Scheduling';
  static const String seeWhoIsFree = 'See who is free';
  static const String schedulingSoon =
      'Scheduling is being rebuilt. It opens from More.';
  static const String availabilitySoon =
      'Availability is being rebuilt. It opens from More.';

  // --- 4d Teacher · me first ------------------------------------------------

  static const String notSignedInYet = 'Not signed in yet';
  static String shiftStarts(String time, String classroom) =>
      'Your shift starts $time · $classroom';
  static const String signMyselfIn = 'Sign myself in';
  static const String geofenceInside =
      'You are inside the center. Location is checked once, for your own '
      'sign-in.';
  static const String geofenceOutside =
      'You are outside the center. Your own sign-in needs you on site; a '
      'student sign-in does not check location.';
  static const String geofenceChecking = 'Checking where you are…';

  static String selfSignedIn(String time) => 'Signed In $time';
  static String selfOnTheClock(String classroom, String span) =>
      '$classroom · $span on the clock';

  static const String lockedTitle = 'Students are locked until you sign in';
  static const String lockedBody =
      'You can see the classroom, you just cannot sign anyone in or out yet.';

  static String ratioWarning(String classroom, String name, String time) =>
      'You are the only staff member in this classroom until $name arrives '
      'at $time. Signing another student in would put $classroom out of '
      'ratio.';

  // --- 4e Nothing to show, and nothing loaded ------------------------------

  static String noResultsTitle(String query, int classrooms) =>
      'No name matching $query in ${_rooms(classrooms)}';
  static const String noResultsBody =
      'Someone with that name may be in a classroom your filter is hiding '
      'right now.';
  static const String searchAllClassrooms = 'Search all classrooms';
  static const String clearFilter = 'Clear filter';

  static String _rooms(int n) =>
      n == 1 ? 'this classroom' : 'these $n classrooms';

  static const String nobodyAbsentEyebrow = 'Nobody absent today';
  static String nobodyAbsentBody(int students, String classrooms) =>
      'All $students students in $classrooms are accounted for.';

  static const String couldNotLoadEyebrow = 'Today could not load';
  static String offlineBody(String asOf) =>
      'You are offline. The list below is from $asOf, and it is read only. '
      'Nothing you tap now will be saved.';
  static const String keepReadingCache = 'Keep reading the cache';
  static const String offlineFootnote =
      'Nothing is queued — sign-ins will save once you are back online.';
  static const String loadError = 'Attendance could not load.';

  static const String emptyDayTitle = 'Nobody on the roll yet';
  static const String emptyDayBody =
      'Once students are enrolled, their day shows up here.';

  // --- 4f A date range ------------------------------------------------------

  static const String attendedTime = 'Attended Time';
  static const String attendedDays = 'Attended Days';
  static const String viewKey = 'View';
  static const String changeRange = 'Change';
  static const String loadingMore = 'Loading more';
  static const String rangeFilterTitle = 'Classrooms';
  static const String rangeFilterSubtitle =
      'Narrow the range to the classrooms you want.';
  static const String rangeEmptyTitle = 'Nothing attended in this range';
  static const String rangeEmptyBody =
      'Widen the range, or clear the classroom filter.';

  // --- Sign In and Sign Out forms ------------------------------------------

  static const String signInTitle = 'Sign In';
  static const String signOutTitle = 'Sign Out';
  static const String dateLabel = 'Date';
  static const String timeLabel = 'Time';
  static const String removeTile = 'Remove';

  static String signInConfirm(int n) =>
      n == 1 ? 'Sign In 1 student' : 'Sign In $n students';
  static String signOutConfirm(int n) =>
      n == 1 ? 'Sign Out 1 student' : 'Sign Out $n students';
  static String signInStaffConfirm(int n) =>
      n == 1 ? 'Sign In 1 staff' : 'Sign In $n staff';
  static String signOutStaffConfirm(int n) =>
      n == 1 ? 'Sign Out 1 staff' : 'Sign Out $n staff';

  static const String signedInByNote =
      'Signed In by is your own name, taken from who is signed in on this '
      'device. It is never typed.';
  static const String signedOutByNote =
      'Signed Out by is your own name, taken from who is signed in on this '
      'device. It is never typed.';

  static const String unexpectedTitle = 'Attention';
  static String unexpectedBody(String names) =>
      '$names not expected today. Sign in anyway?';
  static const String unexpectedAcknowledge = 'Sign in anyway';
  static const String unexpectedNeeded =
      'Acknowledge the students who are not expected today first.';
  static const String geofenceBlocked =
      'You are outside the center. Move on site to sign yourself in.';

  static const String nobodyPicked = 'Pick at least one name first.';
  static String signedInToast(int n) => n == 1 ? '1 signed in' : '$n signed in';
  static String signedOutToast(int n) =>
      n == 1 ? '1 signed out' : '$n signed out';
  static const String saveError = 'That did not save. Try again.';

  // --- Mark Absent, Transfer, Edit times -----------------------------------

  static const String markAbsentTitle = 'Mark Absent';
  static const String reasonLabel = 'Reason';
  static const String reasonHint = 'Why are they out today?';
  static const String reasonRequired = 'A reason is required.';
  static String markedAbsentToast(String name) => '$name marked absent';
  static String undoAbsenceToast(String name) => "$name's absence removed";

  static const String transferTitle = 'Transfer';
  static String transferSubtitle(String from) => 'Currently in $from';
  static const String transferNoRoom =
      'There is no other classroom to transfer into.';
  static String transferToast(String name, String to) => '$name moved to $to';

  static const String editTimesTitle = 'Edit times';
  static const String editTimesNote =
      'Editing a time leaves an audit note with your name on it.';
  static const String editTimesToast = 'Time updated';

  // --- Guardian lens --------------------------------------------------------

  static String childIsIn(String firstName) => '$firstName is in';
  static String childIsOut(String firstName) => '$firstName went home';
  static String childIsAbsent(String firstName) => '$firstName is absent';
  static String childNotMarked(String firstName) =>
      '$firstName is not marked yet';

  static String childSignedInLine(String time, String by) =>
      'Signed In $time by $by, at the door';
  static String childSignedOutLine(String time, String by) =>
      'Signed Out $time by $by';

  static const String scanQr = 'Scan QR';
  static const String thisMonth = 'This month';
  static String monthSummary(int days, int absent, int hours) =>
      '$days days in · $absent absent · $hours hours';
  static const String scanQrSoon =
      'The QR reader lives on the kiosk door screen.';
}
