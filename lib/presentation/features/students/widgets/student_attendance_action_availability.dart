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

  /// Enablement rules driven by today's attendance status:
  /// - SIGNED_IN  -> enable Sign-Out + Transfer only
  /// - SIGNED_OUT -> enable Sign-In only (student can be re-signed-in)
  /// - ABSENT     -> enable Sign-In only
  /// - otherwise (e.g. EXPECTED / NOT_MARKED / null)
  ///   -> enable **Sign-In** + **Mark Absent** only
  bool get canSignIn {
    if (!isActiveProfile) return false;
    if (isSignedInToday) return false;
    // SIGNED_OUT / ABSENT / NOT_MARKED can all be "recovered" by signing in.
    return true;
  }

  bool get canSignOut {
    if (hasSignedOutToday) return false;
    return isSignedInToday;
  }

  bool get canTransfer => canSignOut;

  bool get canMarkAbsent {
    if (!isActiveProfile) return false;
    if (hasSignedOutToday) return false;
    if (isSignedInToday) return false;
    if (isAbsentToday) return false;
    return true;
  }
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

/// Standard tooltip messages explaining why a student attendance action is
/// unavailable for the given [gate] (today's status). Keyed by the action
/// labels used in the attendance pop-up: 'Sign-in', 'Sign-Out', 'Transfer',
/// 'Absent'. Only disabled actions are included.
Map<String, String> studentAttendanceDisabledReasons(
  StudentAttendanceGate gate,
) {
  return <String, String>{
    if (!gate.canSignIn)
      'Sign-in': 'Sign-In can only be done for Students/Staff not signed in.',
    if (!gate.canSignOut)
      'Sign-Out':
          'Sign-Out can only be done for Students/Staff already signed in.',
    if (!gate.canTransfer)
      'Transfer':
          'Transfer can only be done for Students/Staff already signed in.',
    if (!gate.canMarkAbsent) 'Absent': 'Absent can only be marked for Students/Staff not yet signed in',
  };
}

/// Parses today's status string from [GetStudentTodaySignInStatusMapUseCase] / API.
StudentAttendanceGate studentAttendanceGateFromTodayStatus({
  required bool isActiveProfile,
  required String? todayStatusRaw,
}) {
  final su = (todayStatusRaw ?? '').trim().toUpperCase();
  final isSignedIn = su == 'SIGNED_IN';
  final isAbsent = su == 'ABSENT';
  final hasSignedOut =
      su == 'SIGNED_OUT' ||
      su == 'SIGN_OUT' ||
      su == 'COMPLETED' ||
      su == 'SIGNED_OUT_TODAY' ||
      su == 'SIGNEDOUT' ||
      su == 'SIGNED_OUT_FOR_TODAY';
  return StudentAttendanceGate(
    isActiveProfile: isActiveProfile,
    isSignedInToday: isSignedIn,
    isAbsentToday: isAbsent,
    hasSignedOutToday: hasSignedOut,
  );
}
