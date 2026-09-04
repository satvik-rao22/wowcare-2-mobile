import 'package:intl/intl.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';

/// Every word M07 Classrooms says. Shared vocabulary (Students, Staff,
/// Signed In, In Ratio, Apply, Clear all…) stays in `AppStrings`.
///
/// Classrooms, never Rooms. Students, never children. Ratio is always written
/// as counts with a two-state pill, never as a figure.
abstract final class ClassroomsStrings {
  // --- 7a · the list --------------------------------------------------------

  static const String title = 'Classrooms';
  static String headerDate(DateTime d) => DateFormat('EEEE, d MMM').format(d);

  /// The clock time a cached screen was last reached at.
  static String timeOfDay(DateTime d) => DateFormat('H:mm').format(d);

  static String studentsIn(int n) => n == 1 ? '1 student in' : '$n students in';
  static String staffOnDutyAcross(int staff, int classrooms) {
    final s = staff == 1 ? '1 staff' : '$staff staff';
    final c = classrooms == 1 ? '1 classroom' : '$classrooms classrooms';
    return '$s on duty across $c';
  }

  static String enrolledOfPlaces(int enrolled, int places, int percent) =>
      '$enrolled enrolled of $places places · $percent% full';
  static String classroomsOver(int n) =>
      n == 1 ? '1 classroom over' : '$n classrooms over';
  static const String allInRatio = 'All in ratio';

  static const String searchClassrooms = 'Search a classroom';
  static const String chipAll = 'All classrooms';
  static const String chipOverRatio = 'Over ratio';
  static const String chipEmpty = 'Empty';

  static String ofPlaces(int enrolled, int capacity) =>
      '$enrolled of $capacity places';
  static String leading(String name) => '$name leading';
  static const String noLeadAssigned = 'No lead assigned';
  static const String noStaffClockedIn = 'No staff clocked in';
  static String presentCount(int n) => '$n in';
  static String staffCount(int n) => n == 1 ? '1 staff' : '$n staff';
  static const String noStaff = 'No staff';
  static const String noStaffIn = 'No staff in';

  /// The two ratio pills, and the quiet pill for a classroom with nobody in.
  static String moreStaff(int n) => '+$n staff';
  static String needsMoreStaff(int n) =>
      n == 1 ? 'Needs 1 more staff member' : 'Needs $n more staff members';

  static const String everyClassroomCovered = 'Every classroom is covered';
  static const String noClassroomOver =
      'No classroom is over its ratio right now.';
  static const String noEmptyClassrooms = 'Every classroom has students in it.';
  static String noClassroomMatches(String query) =>
      'No classroom called $query';
  static const String createClassroom = 'Create a classroom';

  // --- 7b · no classrooms yet ----------------------------------------------

  static const String noClassroomsTitle = 'No classrooms yet';
  static const String noClassroomsBody =
      'A classroom holds students, staff and a ratio. Make your first one and '
      'the rest of the app has somewhere to put people.';
  static const String noClassroomsHint =
      'Name, age range and capacity. You can assign students after.';

  // --- 7c · one classroom ---------------------------------------------------

  static const String select = 'Select';
  static const String done = 'Done';
  static String isLeadingToday(String name) => '$name is leading today';
  static const String noLeadToday = 'No lead assigned today';
  static const String classroomProfile = 'Classroom profile';
  static const String tileStudentsIn = 'Students in';
  static const String tileStaffOnDuty = 'Staff on duty';
  static const String tilePlacesFilled = 'Places filled';
  static String placesFilled(int enrolled, int capacity) =>
      '$enrolled/$capacity';

  static const String tabStudents = 'Students';
  static const String tabStaff = 'Staff';
  static const String tabNotes = 'Notes';
  static String newCount(int n) => n == 1 ? '1 new' : '$n new';

  static const String searchThisClassroom = 'Search this classroom';
  static const String searchStaffHere = 'Search staff in this classroom';
  static String signedInChip(int n) => 'Signed in $n';
  static String nappingChip(int n) => 'Napping $n';
  static String onDutyChip(int n) => 'On duty $n';
  static String notMarkedChip(int n) => 'Not Marked $n';
  static const String filter = 'Filter';

  static String showingAll(int n) => 'Showing all $n';
  static String showingOf(int shown, int total) => 'Showing $shown of $total';
  static String picked(int n) => '$n picked';

  /// A roster row's second line: age, then today's status and time.
  static String rowSub(String age, String status, String time) =>
      '$age · $status $time';
  static const String napping = 'Napping';

  static const String careNeeds = 'Care needs';
  static const String noCareNeeds = 'None recorded';
  static const String scheduleHere = 'Schedule in this classroom';
  static const List<String> weekdayInitials = <String>['M', 'T', 'W', 'T', 'F'];
  static const String parent = 'Parent';
  static String guardianLinked(String name) => '$name linked';
  static const String noGuardianLinked = 'No guardian linked';
  static const String classroomMove = 'Classroom move';
  static const String noMovePlanned = 'No move planned';
  static const String moreActions = 'More actions';
  static const String openProfile = 'Open profile';

  static const String nobodyMatches = 'Nobody matches that';
  static String turnToggleOff(int n) =>
      'Turn the toggle off to see all $n students.';

  static String staffForStudents(int staff, int students, int needed) {
    final s = staff == 1 ? '1 staff' : '$staff staff';
    final st = students == 1 ? '1 student' : '$students students';
    final need = needed == 1 ? 'One is needed' : '$needed are needed';
    return '$s for $st. $need, so you are covered.';
  }

  static String staffShortFor(int staff, int students, int more) {
    final s = staff == 1 ? '1 staff' : '$staff staff';
    final st = students == 1 ? '1 student' : '$students students';
    final m = more == 1 ? 'One more is needed' : '$more more are needed';
    return '$s for $st. $m.';
  }

  static const String onDuty = 'On duty';
  static const String onBreak = 'On break';
  static String onBreakChip(int n) => 'On break $n';
  static String absentChip(int n) => 'Absent $n';
  static String signedOutChip(int n) => 'Signed Out $n';
  static const String assignStaff = 'Assign Staff';
  static const String assignStudents = 'Assign students';

  /// Why a teacher's classroom has two tabs rather than three (7e).
  static const String noStaffTabNote =
      'No Staff tab. Who else is in the classroom is on the classroom '
      'profile, and assigning staff is admin work.';

  static const String today = 'Today';
  static const String you = 'You';
  static const String writeNote = 'Write a note to the classroom';
  static const String sendNote = 'Send note';
  static const String attachToNote = 'Attach';
  static const String noNotesTitle = 'No notes yet today';
  static const String noNotesBody =
      'Anything the classroom needs to know goes here.';

  // --- 7c · select mode ----------------------------------------------------

  static const String message = 'Message';
  static const String activities = 'Activities';
  static String markAttendanceFor(int n) => 'Mark attendance for $n';
  static const String pickStudentsFirst = 'Pick students first';

  // --- 7d · filter sheet ---------------------------------------------------

  static const String filterStudents = 'Filter students';
  static const String filterStaff = 'Filter staff';
  static const String statusPickOne = 'Status · pick one';
  static String activeCount(int n) => 'Active $n';
  static String upcomingCount(int n) => 'Upcoming $n';
  static const String inClassroomNow = 'In the classroom right now';
  static const String tags = 'Tags';
  static const String tagsCarryNoCount = 'Tags carry no count.';
  static const String designation = 'Designation';
  static const String onTheClock = 'On the clock';
  static const String staffFilterNote =
      'This filters the staff in this classroom.';

  // --- 7e · a teacher's classroom -----------------------------------------

  static const String yourClassroom = 'Your classroom';
  // The action is Sign In, the same verb M04 and the shipped My Day card use
  // for a staff member, so one action never has two names. "On the clock" is
  // kept only as description, never as the label on a key.
  static const String notClockedIn = 'You are not signed in';
  static String shiftLine(String shift) => 'Shift $shift';
  static const String clockInNow = AppStrings.signIn;
  static const String clockInWhy =
      'The classroom unlocks once you are signed in, so a student is never '
      'marked by someone who is not here.';
  static const String lockedTitle = 'Locked until you sign in';
  static const String lockedBody =
      'You can see who is expected, but you cannot mark anyone yet.';
  static String overRatioBy(int n) =>
      n == 1 ? 'Over ratio by 1 student' : 'Over ratio by $n students';
  static String overRatioBody(int students, int staff, int more) {
    final s = staff == 1 ? '1 staff' : '$staff staff';
    final m = more == 1 ? 'One more is needed.' : '$more more are needed.';
    return '$students students with $s. $m';
  }

  static String ageAndEnrolled(String age, int enrolled) =>
      '$age · ${enrolled == 1 ? '1 student' : '$enrolled students'} enrolled';
  static String ageAndPlaces(String age, int places) => '$age · $places places';
  static const String profileCapacityCounts =
      "Classroom profile, capacity and today's counts";
  static const String noLeadYet = 'No lead assigned yet';

  // --- 7f · classroom profile ---------------------------------------------

  static const String editClassroom = 'Edit classroom';
  static String leads(String name) => '$name leads';
  static const String classroomPhoto = 'Classroom photo';
  static const String startUpload = 'Add photo';
  static const String addPhotoTitle = 'Add a photo of the classroom';
  static const String addPhotoHint = 'JPG or PNG, up to 5 MB';
  static String uploadPercent(int pct) => '$pct%';
  static const String uploading = 'Uploading. You can keep working.';
  static String onFile(String file) => '$file on file';
  static const String showsOnList =
      'Shows on the classrooms list and the parent app';
  static const String remove = 'Remove';
  static String uploadFailedAt(int pct) => 'Upload failed at $pct%';
  static String nothingLost(String file) =>
      '$file is still here. Nothing was lost.';
  static const String retry = 'Retry';

  static const String places = 'Places';
  static String ofCapacity(int capacity) => 'of $capacity';
  static String placesLeft(int n) => n == 1 ? '1 place left' : '$n places left';
  static const String classroomFull = 'Full';
  static const String enrolledNow = 'Enrolled now';
  static const String startingSoon = 'Starting soon';

  static const String studentsExpectedToday = 'Students expected today';
  static const String staffExpectedToday = 'Staff expected today';
  static const String signedIn = 'Signed in';
  static const String notMarked = 'Not marked';
  static const String absent = 'Absent';
  static const String signedOut = 'Signed out';

  static const String movements = 'Movements';
  static String movementsMeta(int inCount, int outCount) =>
      '$inCount in · $outCount out';
  static String movesIn(String name) => '$name moves in';
  static String movesOut(String name) => '$name moves out';
  static const String noMovements = 'No movements planned for this classroom.';

  static const String acrossTheCenter = 'Across the center';
  static String classroomCount(int n) =>
      n == 1 ? '1 classroom' : '$n classrooms';
  static const String totalPlaces = 'Total places';
  static const String fullTimeEquivalent = 'Full time equivalent';
  static const String columnClassroom = 'Classroom';
  static const String columnIn = 'In';
  static const String columnStaff = 'Staff';
  static const String columnRatio = 'Ratio';
  static const String ratioEmpty = 'Empty';

  // --- 7g · 7h · assign -----------------------------------------------------

  static const String assignStudentsTitle = 'Assign students';
  static const String assignStaffTitle = 'Assign staff';
  static String toClassroom(String name) => 'to $name';
  static const String stepPickStudents = 'Pick students';
  static const String stepPickStaff = 'Pick staff';
  static const String stepReview = 'Review and submit';
  static const String searchNotInClassroom =
      'Search students not in this classroom';
  static const String searchStaffNotInClassroom =
      'Search staff not in this classroom';
  static const String unassigned = 'Unassigned';
  static const String ageFlag = 'Age';
  static String candidateSub(String age, String classroom) =>
      '$age · $classroom';
  static String belowRangeSub(String age, String minAge) =>
      '$age · below $minAge at start';
  static String aboveRangeSub(String age, String maxAge) =>
      '$age · above $maxAge at start';
  static String alreadyIn(String scope) => 'Already in $scope';

  static String reviewStudents(int n) =>
      n == 1 ? 'Review 1 student' : 'Review $n students';
  static String reviewStaff(int n) => 'Review $n staff';
  static const String pickAStudentFirst = 'Pick a student first';
  static const String pickAStaffFirst = 'Pick a staff member first';
  static String assignNStudents(int n) =>
      n == 1 ? 'Assign 1 student' : 'Assign $n students';
  static String assignNStaff(int n) => 'Assign $n staff';
  static const String back = 'Back';

  static String outsideAgeRangeTitle(int n) => n == 1
      ? 'One student is outside the age range'
      : '$n students are outside the age range';
  static String outsideAgeRangeBody(String name, String age, String band) =>
      '$name is $age and this classroom takes $band from the start date. You '
      'can still assign them.';
  static String outsideAgeRangeBodyMany(String band) =>
      'This classroom takes $band from the start date. You can still assign '
      'them.';

  static const String whatThisChanges = 'What this changes';
  static const String placesFilledLabel = 'Places filled';
  static String goesTo(String name, int enrolled, int capacity) =>
      '$name goes to $enrolled of $capacity places';
  static const String ratioLabel = 'Ratio';
  static String inRatioWith(int staff) =>
      'In Ratio with ${staff == 1 ? '1 staff' : '$staff staff'}';
  static String shortWith(int staff, int more) =>
      '+$more staff needed with ${staff == 1 ? '1 staff' : '$staff staff'}';
  static const String applies = 'Applies';
  static const String immediately = 'Immediately, on submit';
  static String movingInto(String name) => 'Moving into $name';
  static String joining(String name) => 'Joining $name';
  static const String staffInClassroom = 'Staff in the classroom';
  static String becomes(int from, int to) => '$from becomes $to';
  static String holdsUpTo(int n) => 'Holds up to $n students';
  static const String theirShifts = 'Their shifts';
  static const String unchanged = 'Unchanged';
  static String shiftNote(String firstName) =>
      'Being in a classroom is not a shift. $firstName still needs a shift here '
      'before they count towards the ratio for a given hour.';
  static String studentsAssigned(int n, String classroom) => n == 1
      ? '1 student assigned to $classroom'
      : '$n students assigned to $classroom';
  static String staffAssigned(int n, String classroom) => n == 1
      ? '1 staff member assigned to $classroom'
      : '$n staff assigned to $classroom';
  static const String nobodyToAssign = 'Nobody left to assign';
  static const String nobodyToAssignBody =
      'Everyone at the center is already in this classroom.';
  static const String noCandidateMatches = 'Nobody matches that search';

  // --- 7i · refusals --------------------------------------------------------

  static const String moveClassroom = 'Move classroom';
  static const String removeFromClassroom = 'Remove from classroom';
  static String signedInAt(String time) => 'Signed In at $time';
  static const String inClassroomNowTitle =
      'They are in the classroom right now';
  static String moveBlockedBody(String classroom) =>
      "Moving them to $classroom would leave today's attendance recorded "
      'against a classroom they are not in. Sign them out first, or set the '
      'move for tomorrow.';
  static const String moveBlockedBodyGeneric =
      "Moving them now would leave today's attendance recorded against a "
      'classroom they are not in. Sign them out first, or set the move for '
      'tomorrow.';
  static const String moveNow = 'Move classroom now';
  static const String notWhileSignedIn = 'Not while they are signed in';
  static const String transferInstead = 'Transfer them for today instead';
  static const String transferWhy =
      'Their attendance moves, their classroom does not';
  static String signOutFirst(String firstName) => 'Sign $firstName out first';

  static String takeOutOf(String firstName, String classroom) =>
      'Take $firstName out of $classroom?';
  static const String removeBody =
      'They stay enrolled at the center and keep their record. They just will '
      'not belong to a classroom until you put them in one.';
  static const String whatThisCosts = 'What this costs';
  static String dropsTo(String classroom, int enrolled, int capacity) =>
      '$classroom drops to $enrolled of $capacity places';
  static const String leavesNotes =
      "They leave this classroom's notes and activities";
  static const String keptRecord =
      'Kept: their profile, attendance history, documents and family';
  static const String keepThemHere = 'Keep them here';
  static const String takeThemOut = 'Take them out';
  static String removedFrom(String name, String classroom) =>
      '$name is no longer in $classroom';
  static const String pickClassroom = 'Move to which classroom?';
  static String movedTo(String name, String classroom) =>
      '$name moved to $classroom';

  /// View-only toasts: what the persona cannot do.
  static const String viewOnly = 'View only';
  static const String viewOnlyToast =
      'Your role can open classrooms but not change them.';
  static const String offlineToast =
      'No connection. Nothing you tap now would save.';

  // --- 7j · edge states -----------------------------------------------------

  static String offlineAsOf(String time) =>
      'No connection. Showing the classroom as it was at $time.';
  static const String nobodyHereTitle = 'Nobody in this classroom yet';
  static String nobodyHereBody(String classroom, int places, int unassigned) {
    final p = places == 1 ? '1 place' : '$places places';
    if (unassigned == 0) {
      return '$classroom has $p. Assign students from another classroom and '
          'attendance starts working.';
    }
    final u = unassigned == 1 ? '1 student' : '$unassigned students';
    return '$classroom has $p and $u at the center are not in a classroom. '
        'Put them somewhere and attendance starts working.';
  }

  static String noStudentCalled(String query) =>
      'No student called $query here';
  static String noStaffCalled(String query) => 'No staff called $query here';
  static String searchOnlyHere(String classroom) =>
      'This search only looks inside $classroom. Try the full student list to '
      'search the whole center.';
  static const String clearSearch = 'Clear search';
  static const String searchAllStudents = 'Search all students';
  static const String lookNotChangeTitle = 'You can look, not change';
  static const String lookNotChangeBody =
      'Your role can open classrooms but not assign, edit or remove. An admin '
      'at your center can change that on the web.';

  /// Why a key nobody can press is still on the screen.
  static const String deadKeysHint =
      'Keys stay visible and dead, so the classroom does not look broken.';
  static const String couldNotReachTitle = 'We could not reach the classroom';
  static const String couldNotReachBodyNoCache =
      'Nothing loaded. Check your connection and try again.';
  static const String couldNotReachListTitle =
      'We could not reach your classrooms';
  static const String tryAgain = 'Try again';
  static const String loadingClassrooms = 'Loading classrooms…';
  static const String loadingClassroom = 'Loading the classroom…';

  // --- Added · create classroom form ----------------------------------------

  static const String newClassroomTitle = 'New classroom';
  static const String fieldName = 'Classroom name';
  static const String fieldNameHint = 'Sunflower';
  static const String fieldAgeFrom = 'Age from (months)';
  static const String fieldAgeTo = 'Age to (months)';
  static const String fieldAgeHint = '0';
  static const String fieldCapacity = 'Capacity';
  static const String fieldCapacityHint = '16';
  static const String fieldRatio = 'Students per staff';
  static const String fieldRatioHint = '8';
  static const String fieldRatioHelp =
      'The most students one staff member may supervise. Ratio shows as counts, '
      'never a figure.';
  static const String nameRequired = 'Give the classroom a name';
  static const String capacityInvalid = 'Capacity must be a whole number';
  static const String ratioInvalid = 'Students per staff must be 1 or more';
  static const String ageInvalid = 'Age to must be after age from';
  static const String saveClassroom = 'Create classroom';
  static String classroomCreated(String name) => '$name created';
  static const String noAgeLimit = 'No age limit';
  static String ageBand(String from, String to) => '$from to $to';
  static String ageFrom(String from) => 'from $from';
  static String ageUpTo(String to) => 'up to $to';
  static String months(int n) => n == 1 ? '1 mo' : '$n mo';
  static String years(int n) => n == 1 ? '1 yr' : '$n yrs';
}
