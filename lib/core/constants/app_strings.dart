/// All user-visible UI strings.
///
/// Mandate 4: *"No user-visible string literal in a view file. Everything
/// through `AppStrings` (`lib/core/constants/app_strings.dart`)."* This file did
/// not exist — `lib/core/constants/` held only `app_sizes.dart` — so it is
/// created here with the first module's strings and grows per module.
///
/// **What does NOT belong here** (§4, "skip anything not user-visible"): log
/// tags, storage keys, API payload keys, backend enum values. In particular the
/// `SIGNED_IN` / `ABSENT` / `TUESDAY` style constants in the dashboard are
/// backend values compared against API responses, not display text, and are
/// deliberately left where they are.
///
/// Every value below is character-for-character what was rendered before,
/// including the em-dashes and the ellipsis character.
abstract final class AppStrings {
  // ── Dashboard · My Day card ───────────────────────────────────────────────

  static const String myDayTitle = 'My Day';

  /// Initial status line, before the schedule resolves.
  static const String myDayLoadingSchedule = 'Loading schedule…';

  static const String myDayShiftStartsIn = 'Your shift starts in';
  static const String myDayShiftEndsIn = 'Your shift ends in';
  static const String myDayNextShiftStartsIn = 'Your next shift starts in';
  static const String myDayNoSchedules = 'No schedules available';
  static const String myDayNoUpcomingShifts =
      'No upcoming shifts in next 7 days';

  /// Prefixes for the two chips. The value is interpolated after them.
  static const String myDayWorkTimePrefix = 'Work Time : ';
  static const String myDayBreakTimePrefix = 'Break Time : ';

  static const String myDaySignInPinPrefix = 'Your Sign-In Pin: ';

  /// Placeholder shown in place of the PIN when none is stored.
  static const String myDaySignInPinPlaceholder = '--';

  // ── Dashboard · My Day card · self-attendance failures ────────────────────

  static const String myDayNoStaffProfileTransfer =
      'Unable to find your staff profile to transfer.';
  static const String myDayNoStaffProfileMarkAbsent =
      'Unable to find your staff profile to mark absent.';
  static const String myDayNoStaffProfile =
      'Unable to find your staff profile.';

  // ── Dashboard · My Day card · geofence status ─────────────────────────────
  // SEMANTIC: these lines are the non-colour differentiator for the geofence
  // state (§4.3) — the coloured dot alone must not carry the meaning.

  static const String geofenceNotInRange =
      'You are not within geofencing Range';
  static const String geofenceInsideRadius =
      'Inside School Radius — GPS attendance enabled';
  static const String geofenceOutsideRadius =
      'Outside School Radius — move closer to sign in';
  static const String geofenceDisabledByAdmin =
      'GPS sign-in is currently disabled by your school admin.';
  static const String geofencePermissionRequired =
      'Location permission required. Tap to enable.';
  static const String geofenceServicesDisabled =
      'Location services are disabled. Please enable GPS.';
  static const String geofenceChecking = 'Checking your location...';

  // ── Dashboard · My Day card · work-break reminder ─────────────────────────

  /// Button label when a reminder is already on.
  static const String reminderTurnOff = 'Turn off Reminder';

  /// Button label when no reminder is set.
  static const String reminderSend = 'Send reminder';

  // SUSPECT: these two are the SNACKBAR confirmations, and they read as
  // imperatives ("Turn on Reminder") where a confirmation is expected
  // ("Reminder turned on"). Preserved verbatim under GUARDRAIL 1 — flagging
  // rather than fixing, since changing them is a copy decision, not a refactor.
  static const String reminderTurnedOnConfirmation = 'Turn on Reminder';
  static const String reminderTurnedOffConfirmation = 'Turn off Reminder';

  // ── Dashboard · chat-preview row ──────────────────────────────────────────

  static const String chatPreviewEmpty = 'No recent chat';

  /// Fallback title for a classroom conversation whose classroom name has not
  /// resolved yet.
  static const String chatPreviewClassroomFallback = 'Classroom';

  /// Relative-time label for the previous day.
  static const String chatPreviewYesterday = 'Yesterday';
}
