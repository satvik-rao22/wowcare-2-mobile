/// Rules aligned with [StudentAttendanceProfile] / student attendance pop-up:
/// - Sign-in: active profile, not currently signed in, not absent, not signed out for today
/// - Sign-out / Transfer: currently signed in (and not absent)
/// - Mark absent: active profile, not signed in, not already absent
class StudentAttendanceGate {
  const StudentAttendanceGate({
    required this.isActiveProfile,
    required this.isSignedInToday,
    required this.isAbsentToday,
    this.hasSignedOutToday = false,
  });

  final bool isActiveProfile;
  final bool isSignedInToday;
  final bool isAbsentToday;
  final bool hasSignedOutToday;

  bool get canSignIn =>
      isActiveProfile &&
      !isSignedInToday &&
      !isAbsentToday &&
      !hasSignedOutToday;

  bool get canSignOut => isSignedInToday && !isAbsentToday;

  bool get canTransfer => canSignOut;

  bool get canMarkAbsent =>
      isActiveProfile && !isSignedInToday && !isAbsentToday;
}

class StudentAttendanceActionAvailability {
  const StudentAttendanceActionAvailability({
    required this.signInEnabled,
    required this.signOutEnabled,
    required this.transferEnabled,
    required this.absentEnabled,
  });

  static const StudentAttendanceActionAvailability allDisabled =
      StudentAttendanceActionAvailability(
    signInEnabled: false,
    signOutEnabled: false,
    transferEnabled: false,
    absentEnabled: false,
  );

  static const StudentAttendanceActionAvailability allEnabled =
      StudentAttendanceActionAvailability(
    signInEnabled: true,
    signOutEnabled: true,
    transferEnabled: true,
    absentEnabled: true,
  );

  final bool signInEnabled;
  final bool signOutEnabled;
  final bool transferEnabled;
  final bool absentEnabled;

  static StudentAttendanceActionAvailability fromGates(
    Iterable<StudentAttendanceGate> gates,
  ) {
    final list = gates.toList();
    if (list.isEmpty) {
      return allDisabled;
    }
    return StudentAttendanceActionAvailability(
      signInEnabled: list.every((g) => g.canSignIn),
      signOutEnabled: list.every((g) => g.canSignOut),
      transferEnabled: list.every((g) => g.canTransfer),
      absentEnabled: list.every((g) => g.canMarkAbsent),
    );
  }
}

/// Parses today's status string from [GetStudentTodaySignInStatusMapUseCase] / API.
StudentAttendanceGate studentAttendanceGateFromTodayStatus({
  required bool isActiveProfile,
  required String? todayStatusRaw,
}) {
  final su = (todayStatusRaw ?? '').trim().toUpperCase();
  final isSignedIn = su == 'SIGNED_IN';
  final isAbsent = su == 'ABSENT';
  final hasSignedOut = su == 'SIGNED_OUT' ||
      su == 'SIGN_OUT' ||
      su == 'COMPLETED' ||
      su == 'SIGNED_OUT_TODAY';
  return StudentAttendanceGate(
    isActiveProfile: isActiveProfile,
    isSignedInToday: isSignedIn,
    isAbsentToday: isAbsent,
    hasSignedOutToday: hasSignedOut,
  );
}
