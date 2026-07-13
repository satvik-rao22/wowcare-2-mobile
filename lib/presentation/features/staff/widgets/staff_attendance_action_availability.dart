/// Rules aligned with [StaffAttendanceProfile] / staff attendance pop-up:
/// - Sign-in: active profile, not currently signed in, not absent, not signed out for today
/// - Sign-out / Transfer: currently signed in (and not absent)
/// - Mark absent: active profile, not signed in, not already absent, not signed out
class StaffAttendanceGate {
  const StaffAttendanceGate({
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
  /// - SIGNED_OUT -> disable all actions for the day (attendance is done)
  /// - ABSENT     -> disable all actions for the day (no recovery sign-in)
  /// - otherwise (e.g. EXPECTED / NOT_MARKED / null)
  ///   -> enable **Sign-In** + **Mark Absent** only
  bool get canSignIn {
    if (!isActiveProfile) return false;
    if (hasSignedOutToday) return false;
    if (isSignedInToday) return false;
    // Once marked absent for the day, all self-attendance actions are
    // locked out for that date — no recovery sign-in.
    if (isAbsentToday) return false;
    return true;
  }

  bool get canSignOut {
    if (hasSignedOutToday) return false;
    if (isAbsentToday) return false;
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

class StaffAttendanceActionAvailability {
  const StaffAttendanceActionAvailability({
    required this.signInEnabled,
    required this.signOutEnabled,
    required this.transferEnabled,
    required this.absentEnabled,
  });

  /// All actions disabled (e.g. loading or no selection).
  static const StaffAttendanceActionAvailability allDisabled =
      StaffAttendanceActionAvailability(
        signInEnabled: false,
        signOutEnabled: false,
        transferEnabled: false,
        absentEnabled: false,
      );

  /// Default when parents do not pass availability (all tappable).
  static const StaffAttendanceActionAvailability allEnabled =
      StaffAttendanceActionAvailability(
        signInEnabled: true,
        signOutEnabled: true,
        transferEnabled: true,
        absentEnabled: true,
      );

  final bool signInEnabled;
  final bool signOutEnabled;
  final bool transferEnabled;
  final bool absentEnabled;

  static StaffAttendanceActionAvailability fromGates(
    Iterable<StaffAttendanceGate> gates,
  ) {
    final list = gates.toList();
    if (list.isEmpty) {
      return allDisabled;
    }
    return StaffAttendanceActionAvailability(
      signInEnabled: list.every((g) => g.canSignIn),
      signOutEnabled: list.every((g) => g.canSignOut),
      transferEnabled: list.every((g) => g.canTransfer),
      absentEnabled: list.every((g) => g.canMarkAbsent),
    );
  }
}

/// Combines a status-based [StaffAttendanceGate] with the self-service
/// geofencing check that gates all four self-attendance actions: a staff
/// member must be within the school's geofence before *any* of Sign-In,
/// Sign-Out, Transfer or Mark-Absent become available; once within range,
/// [StaffAttendanceGate]'s status rules decide which of those four apply.
extension StaffAttendanceGateGeofence on StaffAttendanceGate {
  StaffAttendanceActionAvailability availabilityWithGeofence(
    bool isWithinGeofence,
  ) {
    return StaffAttendanceActionAvailability(
      signInEnabled: isWithinGeofence && canSignIn,
      signOutEnabled: isWithinGeofence && canSignOut,
      transferEnabled: isWithinGeofence && canTransfer,
      absentEnabled: isWithinGeofence && canMarkAbsent,
    );
  }
}

/// Standard tooltip messages explaining why a staff attendance action is
/// unavailable for the given [gate] (today's status). Keyed by the action
/// labels used in the attendance pop-up: 'Sign-in', 'Sign-Out', 'Transfer',
/// 'Absent'. Only disabled actions are included.
Map<String, String> staffAttendanceDisabledReasons(StaffAttendanceGate gate) {
  return <String, String>{
    if (!gate.canSignIn)
      'Sign-in': 'Sign-In can only be done for Students/Staff not signed in.',
    if (!gate.canSignOut)
      'Sign-Out':
          'Sign-Out can only be done for Students/Staff already signed in.',
    if (!gate.canTransfer)
      'Transfer':
          'Transfer can only be done for Students/Staff already signed in.',
    if (!gate.canMarkAbsent) 'Absent': 'Already marked absent for today.',
  };
}

/// Same as [staffAttendanceDisabledReasons] but also accounts for the
/// self-service geofencing gate: when the staff member is outside the
/// school's geofence, every currently-disabled action reports the
/// geofencing reason first since that is the actual blocker.
Map<String, String> staffAttendanceDisabledReasonsWithGeofence(
  StaffAttendanceGate gate, {
  required bool isWithinGeofence,
}) {
  const geofenceReason = 'You are not within geofencing Range';
  if (isWithinGeofence) {
    return staffAttendanceDisabledReasons(gate);
  }
  return <String, String>{
    if (!gate.canSignIn || !isWithinGeofence) 'Sign-in': geofenceReason,
    if (!gate.canSignOut || !isWithinGeofence) 'Sign-Out': geofenceReason,
    if (!gate.canTransfer || !isWithinGeofence) 'Transfer': geofenceReason,
    if (!gate.canMarkAbsent || !isWithinGeofence) 'Absent': geofenceReason,
  };
}

/// Parses today's status string from [GetStaffTodaySignInStatusMapUseCase] / API.
StaffAttendanceGate staffAttendanceGateFromTodayStatus({
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
  return StaffAttendanceGate(
    isActiveProfile: isActiveProfile,
    isSignedInToday: isSignedIn,
    isAbsentToday: isAbsent,
    hasSignedOutToday: hasSignedOut,
  );
}
