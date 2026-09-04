/// Every word M05 Students says. Shared vocabulary (Students, Sign In,
/// Signed In, Absent, Not Marked, Apply, Clear all…) stays in `AppStrings`.
///
/// No gendered pronouns anywhere: a student is "they", and copy that named a
/// student's pronoun in the design ("She leaves the active list") is written
/// without one here.
abstract final class StudentsStrings {
  // --- 5a Roster ------------------------------------------------------------

  static const String title = 'Students';
  static const String searchHint = 'Search a student';
  static const String selectKey = 'Select';
  static const String doneKey = 'Done';
  static const String filterKey = 'Filter students';
  static const String addStudentKey = 'Add a student';

  static const String activeStudentsTile = 'Active students';
  static const String startingSoonTile = 'Starting soon';
  static String startingSoonEyebrow(int n) => 'Starting soon · $n';

  static const String staffScopeNote =
      'You see the classroom you are rostered to. Adding, editing and '
      'deactivating students is admin work.';
  static String yourClassroom(String classroom) =>
      '$classroom · your classroom';
  static const String notAssigned = 'Not assigned';

  /// `14 students · 8 in · 1 out · 2 absent · 3 not marked`
  static String groupMeta({
    required int students,
    required int signedIn,
    required int signedOut,
    required int absent,
    required int notMarked,
  }) {
    final bits = <String>[
      students == 1 ? '1 student' : '$students students',
      if (signedIn > 0) '$signedIn in',
      if (signedOut > 0) '$signedOut out',
      if (absent > 0) '$absent absent',
      if (notMarked > 0) '$notMarked not marked',
    ];
    return bits.join(' · ');
  }

  static String rowSub(String classroom, String age) => '$classroom · $age';
  static String upcomingRowSub(String classroom) => '$classroom · upcoming';
  static const String noParentFlag = 'No parent';
  static const String upcomingPill = 'Upcoming';
  static const String activePill = 'Active';
  static const String inactivePill = 'Inactive';

  // Expanded row.
  static const String attendanceToday = 'Attendance today';
  static String attendanceAt(String status, String time) => '$status $time';
  static const String tags = 'Tags';
  static const String noTags = 'No tags';
  static const String schedule = 'Schedule';
  static const String birthDate = 'Birth date';
  static const String movesClassroom = 'Moves classroom';
  static const String noMovement = '—';
  static const String moreActions = 'More actions';
  static const String openProfile = 'Open profile';
  static const List<String> weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
  ];

  // Select mode.
  static const String pickStudents = 'Pick students to act on';
  static String signInCount(int n) =>
      n == 1 ? 'Sign In 1 student' : 'Sign In $n students';

  // Actions sheet.
  static String sheetSub(String classroom, String firstTag) =>
      '$classroom · $firstTag';
  static const String actionSignInOut = 'Sign In or Sign Out';
  static const String actionSignInOutNote =
      'Opens the attendance form for this student';
  static const String actionActivity = 'Add an activity';
  static const String actionActivityNote = 'Nappy, meal, nap, photo';
  static const String actionMessage = 'Message the family';
  static const String actionEdit = 'Edit details';
  static const String actionEditNote = 'Name, classroom, schedule, tags';
  static const String actionDeactivate = 'Deactivate';
  static const String actionDeactivateNote =
      'Keeps the record, stops the billing';
  static const String glyphSignIn = 'IN';
  static const String glyphActivity = 'AC';
  static const String glyphMessage = 'MS';
  static const String glyphEdit = 'ED';
  static const String glyphDeactivate = 'OFF';
  static const String noGuardianOnRecord = 'No parent on record';

  // Stand-ins for other modules' flows, until they land.
  static const String attendanceFormSoon =
      'The attendance form opens here once Attendance lands.';
  static const String activityFormSoon =
      'Activities are built in their own module.';
  static const String messagingSoon = 'Messages are built in their own module.';
  static const String editSectionSoon =
      'This section is edited from its own form in a later pass.';

  // --- 5b Filter ------------------------------------------------------------

  static const String filterTitle = 'Filter students';
  static const String statusPickOne = 'Status · pick one';
  static const String classroomSection = 'Classroom';
  static const String tagsSection = 'Tags';
  static const String guardianSection = 'Parent or guardian';
  static const String attendanceSection = 'Attendance today';
  static const String anyTag = 'Any tag';
  static String tagsOf(int picked, int total) => '$picked of $total selected';
  static const String searchTags = 'Search tags';
  static const String searchParents = 'Search parents';
  static String withCount(String label, int n) => '$label $n';

  // --- 5c Profile -----------------------------------------------------------

  static const String tabProfile = 'Profile';
  static const String tabHealth = 'Health';
  static const String tabAttendance = 'Attendance';
  static const String tabDates = 'Dates';
  static const String tabDocuments = 'Documents';
  static const String subAbout = 'About';
  static const String subFamily = 'Family';
  static const String subPickup = 'Pickup';
  static const String subHealth = 'Health';
  static const String subPhysician = 'Physician';
  static const String subExam = 'Exam';
  static const String subImmunization = 'Immunization';

  static String aboutTitle(String firstName) => 'About $firstName';
  static const String fieldStatus = 'Status';
  static String activeSince(String date) => 'Active since $date';
  static const String fieldClassroom = 'Classroom';
  static const String fieldTags = 'Tags';
  static const String fieldGender = 'Gender';
  static const String fieldBirthDate = 'Birth date';
  static String birthDateWithAge(String date, String age) => '$date ($age)';
  static const String fieldSchedule = 'Schedule';
  static const String fieldFte = 'Full time equivalent';
  static const String fieldCustody = 'Student custody';
  static const String fieldSubsidy = 'State subsidy';
  static const String fieldSibling = 'Sibling';
  static const String fieldAddress = 'Address';
  static const String fieldMoves = 'Moves classroom';
  static const String fieldNotes = 'Notes';
  static const String notRecorded = 'Not recorded';
  static const String none = 'None';

  static const String healthTitle = 'Health';
  static const String fieldAllergies = 'Allergies';
  static const String fieldMedications = 'Medications';
  static const String fieldDiet = 'Dietary restrictions';
  static const String fieldPhotoPermission = 'Photo permission';
  static const String permissionGiven = 'Given';
  static const String permissionWithheld = 'Withheld';
  static const String parentsCanEditTitle = 'Parents can edit this';
  static const String parentsCanEditBody =
      'The center lets families keep health records up to date, so the '
      'family sees the same Edit key you do.';

  static const String physicianTitle = 'Physician';
  static const String fieldPhysician = 'Physician';
  static const String fieldEmail = 'Email';
  static const String fieldPhone = 'Phone';

  static const String examTitle = 'Physical examination';
  static const String fieldExamDate = 'Exam date';
  static const String examCompleted = 'Completed';
  static const String examDue = 'Due';

  static const String datesTitle = 'Important dates';
  static const String fieldEnrollment = 'Enrollment date';
  static const String fieldSchoolStart = 'School start date';
  static String startedIn(String classroom) => 'Started in $classroom';
  static const String fieldUpcomingMove = 'Upcoming move';
  static const String fieldLeaving = 'School leaving date';
  static const String datesNoteTitle = 'The five dates the record keeps';
  static const String datesNoteBody =
      'Enrollment, school start, current classroom start, upcoming move and '
      'leaving date. The move date is the one the roster row shows.';

  static const String emergencyContact = 'Emergency contact';
  static const String fieldSignInPin = 'Sign-In PIN';
  static const String fieldLegalCustody = 'Legal custody';
  static const String addedBy = 'Added by';
  static const String allowed = 'Allowed';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String messageKey = 'Message';
  static const String callKey = 'Call';
  static const String renewKey = 'Renew';
  static const String addParent = 'Add a parent';
  static const String addPickup = 'Add a pickup person';
  static String guardiansNote(String emergencyName) =>
      'Up to four parents or guardians per student. $emergencyName is the '
      'emergency contact, so they are called first.';
  static const String guardiansNoteNoEmergency =
      'Up to four parents or guardians per student.';
  static String pickupsNote(String firstName) =>
      'Anyone here can collect $firstName with their own PIN at the kiosk.';

  static String immunizationOverdue(String vaccine, String dueDate) =>
      '$vaccine is overdue. It was due on $dueDate, and no exemption is on '
      'file.';
  static const String immunCompleted = 'Completed';
  static const String immunDue = 'Due';
  static const String immunOverdue = 'Overdue';
  static const String immunExempt = 'Exempt';
  static String givenOn(String date) => 'Given $date';
  static String dueOn(String date) => 'Due $date';
  static String wasDueOn(String date) => 'Was due $date';
  static const String exemptionOnFile = 'Medical exemption on file';

  static String attendanceSummary(int daysIn, int absent, int hours) =>
      '$daysIn days in · $absent absent · $hours hours';
  static const String stillIn = 'still in';

  static const String addDocument = 'Add a document';
  static const String documentsParentNote =
      'A parent can upload here too, when the center allows it.';
  static const String onFile = 'On file';
  static const String expired = 'Expired';
  static String expiresOn(String date) => 'expires $date';
  static String documentDetail(String type, String date) => '$type · $date';
  static const String kindPdf = 'PDF';
  static const String kindImage = 'IMG';

  static const String messageFamily = 'Message family';

  // --- 5d Add a student -----------------------------------------------------

  static const String addTitle = 'Add a student';
  static const String stepStudent = 'The student';
  static const String stepStudentNote = 'Name, classroom, birth date';
  static const String stepGuardian = 'A parent';
  static const String stepGuardianNote = 'Link an existing one, or create';
  static const String stepSchedule = 'The schedule';
  static const String stepScheduleNote = 'Days and times';
  static const String optional = 'Optional';

  static const String statusActive = 'Active';
  static const String statusUpcoming = 'Upcoming';
  static const String statusInactive = 'Inactive';
  static const String firstName = 'First name';
  static const String lastName = 'Last name';
  static const String classroom = 'Classroom';
  static const String pickClassroom = 'Pick a classroom';
  static const String pickDate = 'Pick a date';
  static const String birthDateHint =
      'Required for an active student, and it must be in the past.';
  static const String schoolStartDate = 'School start date';
  static const String schoolStartHint =
      'Required for an upcoming student, and it must be today or later.';
  static const String linkSibling = 'Link a sibling';
  static const String noSiblingYet = 'None yet';
  static const String siblingHint =
      'Students already enrolled with the same last name are offered here.';

  static const String guardianFrom = 'Where the parent comes from';
  static const String existingGuardian = 'Existing parent';
  static const String createGuardian = 'Create new';
  static const String guardianField = 'Parent';
  static const String pickGuardian = 'Pick a parent';
  static String guardianOption(String name, String email) => '$name · $email';
  static const String relation = 'Relation to student';
  static const String pickRelation = 'Pick a relation';
  static const String legalCustody = 'Legal custody';
  static const String custodyHint =
      'A parent without legal custody cannot check the student out.';
  static const String email = 'Email';
  static const String phone = 'Phone';
  static const List<String> relations = <String>[
    'Mother',
    'Father',
    'Guardian',
    'Grandparent',
    'Other',
  ];

  static const String sameTimes = 'Same times every day';
  static const String week = 'Week';
  static const String copyToAllDays = 'Copy to all days';
  static const String closed = 'Closed';
  static String dayTimeTitle(String day, String which) => '$day · $which';
  static const String startTime = 'Start';
  static const String endTime = 'End';

  static const String nextGuardian = 'Next, a parent';
  static const String nextSchedule = 'Next, the schedule';
  static String saveStudent(String fullName) =>
      fullName.isEmpty ? 'Save student' : 'Save $fullName';
  static const String skipGuardian = 'Skip, add a parent later';
  static const String skipSchedule = 'Skip, add the schedule later';
  static String studentAdded(String fullName) => '$fullName added';

  static String siblingsFound(int n) => n == 1
      ? 'One student has the same last name'
      : '$n students have the same last name';
  static const String siblingsAsk = 'Link one of them as a sibling?';
  static const String siblingSkip = 'Not a sibling';
  static const String siblingLink = 'Link as sibling';
  static String siblingSub(String classroom, String status) =>
      '$classroom · $status';

  // Validation.
  static const String firstNameRequired = 'First name is required';
  static const String lastNameRequired = 'Last name is required';
  static const String classroomRequired = 'Classroom is required';
  static const String birthDateRequired = 'Birth date is required';
  static const String birthDatePast = 'Birth date must be in the past';
  static const String schoolStartRequired = 'School start date is required';
  static const String schoolStartFuture =
      'School start date must be today or later';
  static const String guardianRequired = 'Pick a parent, or skip this step';
  static const String relationRequired = 'Relation is required';
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'That does not look like an email';
  static const String phoneRequired = 'Phone is required';
  static const String empty = 'Empty';

  // --- 5e Edit --------------------------------------------------------------

  static String editTitle(String firstName) => "Edit $firstName's details";
  static String problemsSummary(int n) => n == 1
      ? 'One field needs a look before this can save.'
      : n == 2
      ? 'Two fields need a look before this can save.'
      : '$n fields need a look before this can save.';
  static const String classroomMoveHint =
      "Moving a student between classrooms changes both classrooms' ratios "
      'from tomorrow.';
  static const String addTag = 'Add a tag';
  static const String pickTags = 'Pick tags';
  static const String notes = 'Notes';
  static const String notesHint = 'Anything the classroom should know';
  static const String saveChanges = 'Save changes';
  static String changesSaved(String firstName) => "$firstName's details saved";

  // --- 5f Documents ---------------------------------------------------------

  static const String documentsTitle = 'Documents';
  static String documentsSub(String name, String classroom) =>
      '$name · $classroom';
  static const String addDocumentTitle = 'Add a document';
  static const String addDocumentSub = 'Name it, pick a type, choose a file';
  static const String glyphAdd = 'ADD';
  static const String whatIsIt = 'What is it';
  static const String pickType = 'Pick a type';
  static const String expires = 'Expires';
  static const String chooseFile = 'Choose a file';
  static const String camera = 'Camera';
  static const String sending = 'Sending…';
  static String uploadingSub(String size, int percent) =>
      '$size · $percent% sent';
  static String onFileSub(String size) => 'On file · $size · you, just now';
  static String stoppedSub(int percent) =>
      'Stopped at $percent% · nothing was saved';
  static String savedNote(String firstName, String type) =>
      "Saved to $firstName's documents, under $type.";
  static const String failedNote =
      'The upload lost the connection. Nothing was saved, and the name, type '
      'and expiry you typed are still here, so Retry sends it again.';
  static const String view = 'View';
  static const String viewSoon = 'The file viewer opens here on a device.';
  static const String addAnother = 'Add another';
  static const String discard = 'Discard';
  static const String retry = 'Retry';
  static String onFileEyebrow(int n) => 'On file · $n';
  static const String noDocuments = 'No documents on file yet';
  static const List<String> documentTypes = <String>[
    'Registration Forms',
    'Health Forms',
    'Special Program Forms',
    'Birth Certificate',
    'Other',
  ];

  // --- 5g Edge states -------------------------------------------------------

  static const String glyphZero = '0';
  static const String glyphPlus = '+';
  static const String glyphDash = '—';
  static const String glyphBang = '!';

  static String noResultsTitle(String query) => 'Nobody called $query';
  static const String noResultsBody =
      'No active student or parent matches that. Try a first name, or clear '
      'the filters to search the whole center.';
  static const String clearFilters = 'Clear the filters';
  static const String searchInactiveToo = 'Search inactive students too';

  static const String emptyTitle = 'No students yet';
  static const String emptyBody =
      'Add your first student and the roster, the ratios and the attendance '
      'page all start working. You can add parents and a schedule afterwards.';
  static const String bulkImportNote = 'Bulk import is on the web';

  static const String viewOnlyBanner =
      'You only have view access here. Contact your school if you need '
      'permission to add or change information.';
  static const String viewOnlyTitle = 'Students are not shared with you';
  static String viewOnlyBody(String school) =>
      'Your role at $school can read attendance but not the student records. '
      'An Admin can turn the Students module on for you.';
  static const String messageAdmin = 'Message an Admin';

  static String offlineBanner(String time) =>
      'No signal. You are looking at the roster as it was at $time.';
  static const String offlineTitle = 'Waiting for a signal';
  static String offlineBody(int n) =>
      'The $n students saved on this phone are readable. Adding, editing and '
      'checking in need a connection, so those keys stay off until you are '
      'back.';

  static const String loadError = 'The roster could not be loaded.';
  static const String profileLoadError =
      "This student's record could not be loaded.";
  static const String saveError = 'That did not save. Try again.';

  // --- 5h Deactivate --------------------------------------------------------

  static String deactivateTitle(String firstName) => 'Deactivate $firstName?';
  static String deactivateSub(String classroom, String enrolled) =>
      '$classroom · enrolled $enrolled';
  static const String whatChanges = 'What changes today';
  static const String costRoster = 'Roster and attendance';
  static const String costRosterValue = 'Leaves the active list';
  static const String costActivities = 'Activities and messages';
  static const String costActivitiesValue = 'No longer available for them';
  static const String costKept = 'Kept on file';
  static const String costKeptValue = 'Records, documents, history';
  static const String deactivateWarning =
      'Nothing is deleted. An inactive student can be reactivated from the '
      'Inactive list, and only then deleted.';
  static String deactivateKey(String firstName) => 'Deactivate $firstName';
  static const String keepActive = 'Keep them active';
  static const String deleteFootnote = 'Delete stays on inactive records only.';
  static String deactivated(String fullName) => '$fullName is now inactive';
}
