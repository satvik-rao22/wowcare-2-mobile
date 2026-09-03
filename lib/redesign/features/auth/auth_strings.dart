/// Every word M01 Authentication and Kiosk says.
///
/// Shared vocabulary (Sign In, Signed In, Logout, Students…) stays in
/// `AppStrings`; this file holds only what these eleven screens say. Templated
/// copy is a function so the sentence stays in one piece.
///
/// There is no sign-up copy here and never will be: accounts are created on
/// the web by the school administrator.
abstract final class AuthStrings {
  // --- 1a Sign In -----------------------------------------------------------

  static const String welcomeBack = 'Welcome back';
  static const String signInSubtitle = 'Sign in to keep the day running';
  static const String emailHint = 'Email address';
  static const String passwordHint = 'Password';
  static const String forgotPassword = 'Forgot password?';

  /// The auth key. Lower-case "in": this is entering the app, not the
  /// attendance verb.
  static const String signInKey = 'Sign in';
  static const String signingIn = 'Signing in';
  static const String rejected =
      'Email or password is incorrect. Check both and try again.';
  static const String accountsNote =
      'Accounts are created by your school administrator.';
  static const String needAccess = 'Need access? Ask your Admin or Director.';

  // --- 1b Choose organization ----------------------------------------------

  static String stepOf(int step, int total) => 'Step $step of $total';
  static const String chooseOrganization = 'Choose organization';

  static String belongsTo(int n) => n == 1
      ? 'Your account belongs to one group.'
      : 'Your account belongs to ${_word(n)} groups.';

  static String roleHere(String role) => 'Your role here: $role';
  static const String continueKey = 'Continue';

  // --- 1c Choose school -----------------------------------------------------

  static const String chooseSchool = 'Choose school';
  static const String searchSchools = 'Search schools';
  static const String currentSchool = 'Current school';
  static const String pendingApproval = 'Pending approval';
  static const String schoolPendingMessage =
      'This school is pending approval. Please contact your administrator.';
  static const String noSchoolsFound = 'No schools found';

  // --- 1d Forgot password ---------------------------------------------------

  static const String resetPassword = 'Reset password';
  static const String resetIntro =
      "Enter the email on your account. We'll send a link to set a new "
      'password. It expires in 15 minutes.';
  static const String sendResetLink = 'Send reset link';
  static const String backToSignIn = 'Back to sign in';
  static const String enterValidEmail = 'Please enter a valid email address';
  static const String resetLinkFailed =
      'The link could not be sent. Check the address and try again.';

  // --- 1e Check your email --------------------------------------------------

  static const String checkEmail = 'Check your email';
  static const String sentTo = 'We sent a reset link to';
  static const String didntGetIt = "Didn't get it?";
  static const String checkSpam =
      'Check spam, or confirm the address with your Admin. School mail '
      'filters sometimes hold it briefly.';
  static String resendIn(String clock) => 'Resend in $clock';
  static const String resend = 'Resend link';
  static const String resent = 'Reset link sent again';

  /// Added: the fixture has no inbox to tap a link in, so 1e offers the way
  /// through to 1f.
  static const String haveLink = 'Already have the link? Set new password';

  // --- 1f Set new password --------------------------------------------------

  static const String newPassword = 'New password';
  static const String newPasswordHint = 'New password';
  static const String confirmPasswordHint = 'Confirm new password';
  static const String ruleLength = 'At least 8 characters';
  static const String ruleNumberSymbol = 'One number and one symbol';
  static const String ruleMatch = 'Both entries match';
  static const String saveAndSignIn = 'Save and sign in';
  static const String passwordChanged = 'Password changed successfully';
  static const String passwordChangeFailed =
      'The password could not be saved. Try again.';

  // --- 2b The door screen ---------------------------------------------------

  static const String scanTheQr = 'Scan the QR Code';

  /// One name for the PIN everywhere: Sign-In PIN. Never "Kiosk PIN".
  static const String enterPin = 'Enter your Sign-In PIN';
  static const String nextKey = 'Next';
  static const String invalidPin = 'Invalid PIN. Please try again.';
  static const String shortPin = 'Please enter a 4-digit PIN';
  static const String pinCancelled = 'PIN entry cancelled';
  static const String backspace = 'Delete last digit';

  static String staffSignedIn(String name) => '$name is Signed In';
  static String staffSignedOut(String name) => '$name is Signed Out';

  static const String leaveKiosk = 'Leave kiosk mode';
  static const String leaveKioskSubtitle =
      'Enter an admin Sign-In PIN to return to the app.';

  // --- 2e The QR's states ---------------------------------------------------

  static const String loadingQr = 'Loading QR Code…';
  static const String qrNotGenerated = 'QR not generated yet';
  static const String qrFailed = 'Failed to generate QR';
  static const String qrUnable = 'Unable to load QR code. Please try again.';
  static const String schoolCodeMissing =
      'School code not found. Please login again.';
  static const String refreshQr = 'Refresh QR code';

  // --- 2a The scanner -------------------------------------------------------

  static const String scanQrCode = 'Scan QR Code';
  static const String inRange = 'In range';
  static const String pointCamera =
      'Point the camera at the QR code on the kiosk screen.';
  static const String torch = 'Torch';
  static const String flipCamera = 'Flip camera';
  static const String rescan = 'Rescan';
  static const String codeAccepted = 'Code accepted';
  static const String closeScanner = 'Close scanner';

  // --- 2c and 2d The family -------------------------------------------------

  static const String whoIsArriving = "Who's arriving?";
  static const String whoIsLeaving = "Who's leaving?";
  static String codeAcceptedAt(String time) => 'Code accepted · $time';
  static const String insideGeofence = 'Inside the school geofence';
  static const String recordedAgainst = 'Recorded against';
  static String recordedNote(String guardian) =>
      '$guardian, from this kiosk. Sign In and Sign Out record the time, '
      'the method and who did it.';
  static const String selectAStudent = 'Select a student';
  static const String staffNote =
      'Staff entering their own PIN sign themselves in instead.';
  static const String signInOrOut = 'Sign In / Sign Out';
  static const String onThisPin = 'On this PIN';

  static String studentLine(String classroom, String status) =>
      '$classroom · $status';

  static String studentsSignedIn(int n) =>
      n == 1 ? '1 student Signed In' : '$n students Signed In';
  static String studentsSignedOut(int n) =>
      n == 1 ? '1 student Signed Out' : '$n students Signed Out';

  static String _word(int n) => switch (n) {
    2 => 'two',
    3 => 'three',
    4 => 'four',
    5 => 'five',
    6 => 'six',
    7 => 'seven',
    8 => 'eight',
    9 => 'nine',
    _ => '$n',
  };
}
