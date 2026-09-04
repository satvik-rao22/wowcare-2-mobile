/// All the copy M08 Activities says.
///
/// Shared vocabulary (Students, Sign In, Cancel, Apply) stays in
/// `AppStrings`; everything here is this module's own. Templated copy is a
/// function so a widget never builds a sentence out of pieces.
abstract final class ActivitiesStrings {
  // --- 8a / 8b the feed -----------------------------------------------------

  static const String dayMode = 'Day';
  static const String rangeMode = 'Range';
  static const String rangeSeparator = 'to';

  /// "Today · Sunflower Room".
  static String dayScope(String classroom) => 'Today · $classroom';

  /// "Thu 20 Aug · Sunflower Room", on a day that is not today.
  static String pastScope(String label, String classroom) =>
      '$label · $classroom';

  /// "4 days · Sunflower Room".
  static String rangeScope(int days, String classroom) =>
      '$days days · $classroom';

  static const String inNow = 'In now';

  /// The recessed note under the list when In now is on.
  static String inNowNote(int hidden) =>
      'In now hides $hidden ${hidden == 1 ? 'student' : 'students'} who have '
      'gone home. Turn it off to see everyone who attended.';

  static const String showAttendance = 'Show attendance';
  static const String hideAttendance = 'Hide attendance';
  static const String attendanceCardLabel = 'Attendance';

  /// The attendance card the rail can show above the first activity.
  static String attendanceCardTitle(int students) =>
      'Sign In · $students students';

  static const String allTypes = 'All';

  /// "2 waiting for your approval".
  static String pendingBanner(int count) => '$count waiting for your approval';

  static const String loadMore = 'Load 10 more';

  /// "Showing 10 of 23 · the feed pages ten at a time".
  static String loadMoreSub(int shown, int total) =>
      'Showing $shown of $total · the feed pages ten at a time';

  /// "31 cards", beside the title in range mode.
  static String cardCount(int count) =>
      '$count ${count == 1 ? 'card' : 'cards'}';

  /// "9 activities", on a range day header.
  static String dayCount(int count) =>
      '$count ${count == 1 ? 'activity' : 'activities'}';

  static const String additionalNotesEyebrow = 'Additional notes';

  /// "Ivy Chen · went home 3:20 pm".
  static String wentHome(String name, String at) => '$name · went home $at';

  static const String filterKey = 'Filter activities';
  static const String uploaderKey = 'Image Uploader';
  static const String openActivity = 'Open activity';
  static const String logActivity = 'Log an activity';

  // --- 8u the four edges ----------------------------------------------------

  static const String emptyTitle = 'Nothing logged yet today';
  static const String emptyBody =
      'The room signed in at 7:58. The first activity of the day usually '
      'lands around breakfast.';
  static const String emptyKey = 'Add the first one';

  static const String noResultsTitle = 'No activities match';
  static const String noResultsBody =
      'Nothing on this day carries every filter you have picked. Clearing '
      'the status filter brings the cards back.';
  static const String noResultsKey = 'Clear filters';

  static const String viewOnlyTitle = 'You can read this room';
  static const String viewOnlyBody =
      'Your role can open activities in this classroom, but not add or edit '
      'them.';

  static const String offlineTitle = 'You are offline';

  /// "This is the last page that loaded, at 9:12 am. …".
  static String offlineBody(String at) =>
      'This is the last page that loaded, at $at. Nothing new arrives and '
      'nothing can be added until you are back.';

  static const String loadError = 'The feed did not load.';
  static const String saveError = 'That did not save. Try again.';

  // --- 8s the staff gate ----------------------------------------------------

  static const String signInFirst = 'Please sign in to create an activity.';
  static const String notSignedInTitle = 'You are not signed in';

  /// "Shift 8:00 am – 4:30 pm · Sunflower Room".
  static String shiftLine(String from, String to, String classroom) =>
      'Shift $from – $to · $classroom';

  /// "Your Sign-In Pin 4417 · type it on the kiosk if the code will not scan".
  static String pinLine(String pin) =>
      'Your Sign-In Pin $pin · type it on the kiosk if the code will not scan';

  /// "Sunflower Room · today".
  static String roomToday(String classroom) => '$classroom · today';

  // --- 8t the guardian's feed ----------------------------------------------

  /// "Amara's day".
  static String guardianTitle(String firstName) => "$firstName's day";

  static const String acknowledge = 'Acknowledge';

  /// "Acknowledged 9:41 am".
  static String acknowledged(String at) => 'Acknowledged $at';

  static const String acknowledgedToast = 'Thank you, that is acknowledged.';

  // --- 8c the filter sheet --------------------------------------------------

  static const String filterTitle = 'Filter activities';
  static const String tagsGroup = 'Tags';
  static const String typeGroup = 'Activity Type';
  static const String statusGroup = 'Status';

  /// "Apply 2 filters", or "Apply filters" with nothing picked.
  static String applyFilters(int count) =>
      count == 0 ? 'Apply filters' : 'Apply $count filters';

  // --- 8d one activity open -------------------------------------------------

  /// "Logged by Dana Whitfield · Lead Teacher".
  static String loggedBy(String name, String designation) =>
      'Logged by $name · $designation';

  static const String attachmentLabel = 'Attachment';
  static const String approve = 'Approve';
  static const String reject = 'Reject';

  static const String editNoteAdmin =
      'Admin can edit any activity except an attendance card.';
  static const String editNoteOwnPending =
      'Staff may edit their own while it is pending. Rejected locks edit for '
      'everyone.';
  static const String editNoteOther =
      "Not this viewer's activity, so edit and delete are gone, not greyed.";

  /// "Approved, and waiting on Amara's guardian to acknowledge."
  static String ackPendingBody(String firstName) =>
      "Approved, and waiting on $firstName's guardian to acknowledge.";

  static const String deleteTitle = 'Delete this activity?';
  static const String deleteBody =
      'The card goes for everyone, including the family. This cannot be '
      'undone.';
  static const String deletedToast = 'Activity deleted.';
  static const String editSoon = 'Editing an activity is being rebuilt.';

  // --- 8e the approvals queue ----------------------------------------------

  static const String approvalsTitle = 'Waiting for approval';

  /// "2 waiting for you", or "Nothing waiting".
  static String queueTitle(int left) =>
      left == 0 ? 'Nothing waiting' : '$left waiting for you';

  static const String queueSubtitle =
      'Incidents and medication always need a signature. Nothing is deleted '
      'here.';
  static const String queueDoneNote =
      'The teacher who logged it is notified. It stays in the feed either '
      'way.';
  static const String queueFootnote =
      'Rejecting keeps the card and locks it: staff can no longer edit or '
      'delete it, so the record cannot quietly change.';
  static const String queueEmptyTitle = 'Nothing waiting for you';
  static const String queueEmptyBody =
      'Every incident and medication card on this day has a signature '
      'against it.';

  /// "Incident approved."
  static String approvedToast(String kind) => '$kind approved.';
  static String rejectedToast(String kind) => '$kind rejected.';

  // --- 8f step 1, who it is for --------------------------------------------

  static const String pickTitle = 'Who is this for?';
  static const String step1 = 'Step 1 of 3';
  static const String step2 = 'Step 2 of 3';
  static const String step3 = 'Step 3 of 3';
  static const String searchStudent = 'Search a student';
  static const String tagsPlaceholder = 'Tags';

  /// "Showing 9 signed in now".
  static String inNowOn(int count) => 'Showing $count signed in now';

  /// "Showing all 10 who attended today".
  static String inNowOff(int count) => 'Showing all $count who attended today';

  static const String goneHomeNote =
      'A student who has gone home can still be logged for, as long as the '
      'activity time falls inside the day they attended.';

  static const String pickNobody = 'Pick at least one student';

  /// "Next · 2 students".
  static String pickNext(int count) =>
      'Next · $count ${count == 1 ? 'student' : 'students'}';

  static const String rosterEmptyTitle = 'Nobody attended this day';
  static const String rosterEmptyBody =
      'An activity has to belong to a student who was here, so there is '
      'nobody to log for yet.';

  // --- 8g step 2, choose activity ------------------------------------------

  static const String chooseTitle = 'Choose activity';
  static const String change = 'Change';

  /// "2 selected · Sunflower Room".
  static String pickedLine(int count, String classroom) =>
      '$count selected · $classroom';

  /// "16 students · Sunflower Room".
  static String studentsLine(int count, String classroom) =>
      '$count students · $classroom';

  /// "Micah Bell · Sunflower Room".
  static String oneStudentLine(String name, String classroom) =>
      '$name · $classroom';

  /// "Whole room · Sunflower Room".
  static String wholeRoomLine(String classroom) => 'Whole room · $classroom';

  static const String incidentSingleTip =
      'Incident can only be recorded for a single student.';
  static const String napMixedTip =
      'Nap is disabled for a mixed selection. Pick all napping or all not '
      'napping.';

  // --- 8h to 8r, the eleven forms ------------------------------------------

  static const String whoAndWhen = 'Who and when';
  static const String dateLabel = 'Date';
  static const String timeLabel = 'Time';

  /// "Times use the school's timezone, America/New_York."
  static String timezoneNote(String zone) =>
      "Times use the school's timezone, $zone.";

  static const String signOff = 'Sign-off';
  static const String staffPresent = 'Staff Present';
  static const String adminPresent = 'Admin Present';
  static const String parentPresent = 'Parent Present';
  static const String peoplePresent = 'People present';
  static const String notesAndApproval = 'Notes and approval';

  static const String requiresApproval = 'Requires Admin Approval';
  static const String requiresApprovalSub =
      'A director reviews this before families can see it.';

  static const String description = 'Description';
  static const String descriptionHint = 'Enter Description';

  /// "49 / 500".
  static String charCount(int used, int max) => '$used / $max';

  static const String addKey = 'Add';
  static const String addedToast = 'Activity added.';

  /// "Sign in on the kiosk before you log an activity."
  static const String notSignedInGate =
      'Sign in on the kiosk before you log an activity.';

  // Nap, 8h.
  static const String napSection = 'Nap details';
  static const String napStart = 'Nap Start Time';
  static const String napEnd = 'Nap End Time';
  static const String napDuration = 'Duration';
  static const String napDurationHelp = 'Calculated from the start and end '
      'time.';
  static const String napPending = 'Waiting on an end time';
  static const String napReminder = 'Reminder every 15 minutes';
  static const String napReminderSub =
      'Nudges the room to check on sleeping students until the nap is '
      'closed.';

  // Bathroom, 8i.
  static const String bathroomSection = 'Bathroom details';
  static const String bathroomType = 'Bathroom Type';
  static const String bathroomSubType = 'Sub Type';
  static const String diaperSize = 'Diaper Size';

  // Bottle, 8j.
  static const String bottleSection = 'Bottle details';
  static const String amountConsumed = 'Amount Consumed';
  static const String ounces = 'oz';
  static const String bottleStepHelp =
      'Steps of half an ounce. The bottle plan on file is 4 oz.';
  static const String consumptionStatus = 'Consumption Status';
  static const String less = 'Half an ounce less';
  static const String more = 'Half an ounce more';

  // Meal, 8k.
  static const String mealSection = 'Meal details';
  static const String mealType = 'Meal Type';
  static const String quantity = 'Quantity';

  // Incident, 8l.
  static const String incidentSection = 'What happened';
  static const String whatHappened = 'What happened?';
  static const String firstAid = 'First Aid Administered';
  static const String firstAidSub =
      'Cold pack, plaster, or anything else from the first aid box.';
  static const String additionalNotes = 'Additional Notes';

  // Medication, 8o.
  static const String medicationSection = 'Medication details';
  static const String medicationHelp =
      'Write what was given, how much, and how the student was afterwards.';

  // Notes, 8p.
  static const String noteSection = 'The note';

  // Outdoor, 8q.
  static const String outdoorSection = 'Outdoor details';

  // Learning, 8r.
  static const String learningSection = 'Learning details';
  static const String category = 'Category';
  static const String subCategory = 'Sub Category';

  // Photo and video, 8m / 8n.
  static const String photosSection = 'Photos';
  static const String photosLabel = 'Photos';
  static const String videoSection = 'Video';
  static const String videoLabel = 'Video';

  /// "3 of 5 added".
  static String mediaCount(int added, int max) => '$added of $max added';

  static const String addPhoto = 'Add a photo';
  static const String requiredMissing = 'Fill in the required fields first.';

  // --- 8v the image uploader ------------------------------------------------

  static const String uploaderTitle = 'Image Uploader';
  static const String uploaderTab = 'Upload';
  static const String chooseMedia = 'Choose Media';

  /// "Only image files are supported, max 10".
  static String uploaderLimit(int max) =>
      'Only image files are supported, max $max';

  /// "Selected Images (4)".
  static String selectedImages(int count) => 'Selected Images ($count)';

  static const String nonePickedTitle = 'No images picked yet';
  static const String uploaderChooseSub =
      'Nothing picked yet. Only image files, up to 10 at a time.';
  static const String uploaderPickedSub =
      'Tap the cross on a thumbnail to drop one before you upload.';
  static const String uploaderUploadingSub =
      'One presigned upload per file. The bar is the real overall '
      'percentage.';
  static const String uploaderFailedSub =
      'The one that failed stays selected so Retry loses nothing.';

  /// "Uploading… 62%".
  static String uploadingPercent(int percent) => 'Uploading… $percent%';

  /// "3 of 4 images uploaded".
  static String uploadedOfTotal(int done, int total) =>
      '$done of $total images uploaded';

  static const String uploadFailedBody =
      'One failed. It is still selected, so Upload retries only that file.';

  static const String uploadKeyIdle = 'Upload';

  /// "Upload 4 images".
  static String uploadKey(int count) =>
      'Upload $count ${count == 1 ? 'image' : 'images'}';

  static const String uploadKeyBusy = 'Uploading…';

  /// "Retry 1 image".
  static String retryKey(int count) =>
      'Retry $count ${count == 1 ? 'image' : 'images'}';

  static const String removeImage = 'Remove this image';

  static const String tileReady = 'Ready';
  static const String tileDone = 'Done';
  static const String tileQueued = 'Queued';
  static const String tileFailed = 'Failed';

  /// "62%", on a tile that is part-way up.
  static String tilePercent(int percent) => '$percent%';

  static const String uploadedToast = 'Images uploaded.';
}
