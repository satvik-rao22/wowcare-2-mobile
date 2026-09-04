/// Every word M13 My Profile says.
///
/// Shared vocabulary (Save, Cancel, Edit, Logout, Try again) stays in
/// `AppStrings`. Templated copy is a function so the sentence stays whole.
abstract final class ProfileStrings {
  // --- Titles ---------------------------------------------------------------

  static const String myProfile = 'My Profile';

  /// The guardian's own record (13c).
  static const String me = 'Me';
  static const String editMyProfile = 'Edit My Profile';
  static const String notificationSettings = 'Notification Settings';
  static const String notificationSettingsSubline = 'Saved the moment you tick';
  static const String changePassword = 'Change Password';

  // --- Hero card ------------------------------------------------------------

  /// "Director · Maple View", "Guardian · Maple View".
  static String roleLine(String designation, String school) =>
      '$designation · $school';

  static const String loadedJustNow = 'Loaded just now';
  static String savedOnPhone(String time) => 'Saved on this phone · $time';

  static const String changePhoto = 'Change photo';
  static const String noPhotoHint =
      'A photo helps a parent recognize you in a Room Chat. It is optional '
      'and you can remove it later.';
  static const String chooseFromLibrary = 'Choose from library';
  static const String uploading = 'Uploading';
  static const String uploadingNote =
      'The last stretch says Finalizing while the server stores it.';
  static const String photoFailedTitle = 'Photo did not upload';
  static const String photoFailedBody =
      'Your old photo is untouched and the new one is still on your phone. '
      'Nothing else on this screen was affected.';
  static String percent(double fraction) =>
      '${(fraction.clamp(0, 1) * 100).round()}%';

  static const String photoSheetTitle = 'Profile photo';
  static const String photoSheetSubtitle = 'Parents see this in Room Chat';
  static const String removePhoto = 'Remove photo';
  static const String photoRemoved = 'Photo removed';
  static const String photoUpdated = 'Photo updated';

  // --- Detail card ----------------------------------------------------------

  static const String name = 'Name';
  static const String email = 'Email';
  static const String cannotBeEdited = 'Cannot be edited';
  static const String phoneNumber = 'Phone Number';
  static const String address = 'Address';

  /// A value the record does not carry yet (13f failed state).
  static const String missingValue = '—';

  // --- Work schedule --------------------------------------------------------

  static const String workSchedule = 'Work Schedule';
  static const String adminOnly = 'Admin only';
  static String timeRange(String start, String end) => '$start – $end';
  static String breakRange(String range) => 'Break $range';
  static const String noSchedule = 'No schedule set';

  /// The three-letter day chips, MON through SUN.
  static const List<String> dayShort = <String>[
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  // --- Actions card ---------------------------------------------------------

  static const String signInPin = 'Sign-In PIN';
  static const String show = 'Show';
  static const String hide = 'Hide';
  static const String pinMask = '••••';

  static String versionLine(String version, String build) =>
      'Version $version · build $build';

  // --- Guardian (13c) -------------------------------------------------------

  static const String yourChildren = 'Your children';
  static const String open = 'Open';
  static String childLine(String classroom, String status) =>
      '$classroom · $status';
  static String childTimedLine(String classroom, String status, String time) =>
      '$classroom · $status $time';
  static const String guardianNote =
      'No work schedule, no Switch Profile and no staff record: a guardian '
      'holds one role here. Their PIN is shown so they can type it on the '
      'kiosk; the app never asks them for it.';

  // --- States (13f) ---------------------------------------------------------

  static const String loadingProfile = 'Loading your profile…';
  static const String loadFailedTitle = 'Failed to load profile';
  static const String loadFailedBody =
      'Your name, email and role still show. They were kept from sign-in. '
      'Only the fuller record is missing.';
  static const String offlineBanner =
      'No connection. Showing what was saved on this phone.';
  static const String offlineNote =
      'Edit, Change Password, Switch Profile and updating your photo all need '
      'a connection. Viewing your own record does not.';

  // --- Edit My Profile (13b) ------------------------------------------------

  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String street = 'Street';
  static const String addressLine2 = 'Address Line 2';
  static const String city = 'City';
  static const String zipCode = 'Zip Code';
  static const String state = 'State';
  static const String country = 'Country';
  static const String emailHelp =
      'Your email is your sign-in. An Admin changes it on the web.';
  static const String chooseState = 'Choose a state';
  static const String profileSaved = 'Profile saved';
  static const String saveFailed = 'Could not save your profile. Try again.';

  static const String firstNameRequired = 'First Name is required';
  static const String firstNameInvalid =
      'First Name must be letters only and max 50 characters';
  static const String lastNameRequired = 'Last Name is required';
  static const String lastNameInvalid =
      'Last Name must be letters only and max 50 characters';
  static const String phoneRequired = 'Phone Number is required';
  static const String phoneInvalid =
      'Please enter a valid 10-digit phone number';
  static const String streetRequired = 'Street is required';
  static const String streetTooLong =
      'Street address cannot exceed 150 characters';
  static const String cityRequired = 'City is required';
  static const String cityTooLong = 'City name cannot exceed 50 characters';
  static const String zipRequired = 'Zip Code is required';
  static const String zipInvalid =
      'Zip Code must be 5 digits (12345) or ZIP+4 (12345-6789)';
  static const String stateRequired = 'State is required';
  static const String line2TooLong =
      'Address Line 2 cannot exceed 150 characters';

  // --- Notification Settings (13e) ------------------------------------------

  static const String whatHappens = 'What happens';
  static const String inApp = 'In-App';
  static const String emailChannel = 'Email';
  static const String push = 'Push';

  /// The mark in a greige box: that channel is not offered for the group.
  static const String notOfferedMark = '—';
  static const String notOfferedNote =
      'A greige box means that channel is not offered for that group, not '
      'that it is switched off. Only the channels a group really supports '
      'can be ticked.';
  static const String savesNote =
      'Each tick saves that one group immediately and the row dims while it '
      'is in flight. If the save fails, the tick goes back to where it was '
      'and the reason appears as a top toast.';
  static const String loadingPreferences = 'Loading your preferences…';
  static const String noPreferences = 'No notification preferences yet';
  static const String noPreferencesBody =
      'Your school has not set up any notification groups for you.';
  static const String preferenceSaveFailed =
      'Could not save that preference. It has been put back.';

  // --- Change Password ------------------------------------------------------

  static const String currentPassword = 'Current password';
  static const String newPassword = 'New password';
  static const String confirmPassword = 'Confirm new password';
  static const String passwordRules =
      'At least 8 characters and one special character.';
  static const String passwordChanged = 'Password changed';
  static const String currentPasswordRequired =
      'Please enter your current password';
  static const String newPasswordRequired = 'Please enter a new password';
  static const String newPasswordInvalid =
      'Password must contain at least 8 characters and one special character';
  static const String confirmMismatch =
      'New password and confirm password do not match';
  static const String newSameAsCurrent =
      'New password must be different from current password';
  static const String changePasswordFailed =
      'Could not change your password. Try again.';
}
