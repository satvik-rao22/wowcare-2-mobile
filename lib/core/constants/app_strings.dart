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
  // Populated per-feature during migration. Scheduling's entries land here
  // in the theming pass (Mandate 4).

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

  // ── Newsletter ────────────────────────────────────────────────────────────
  // Naming: `<feature><Context><Thing>`, lowerCamelCase, feature first — the
  // same shape as the dashboard entries above.
  //
  // NOT here, deliberately: newsletter TITLES, SUBTITLES and BODY HTML. Those
  // arrive from the backend with the record and are author-written content,
  // not UI copy. Nor are the `SENT`/`DRAFT` status values, which are compared
  // against API responses (§4, "skip anything not user-visible").

  /// Tab label on the staff/admin newsletter tab.
  static const String newsletterSentTab = 'Sent';

  /// Screen header and tab label on the parent newsletter screen.
  static const String newsletterTitle = 'Newsletter';

  /// Search field placeholder on both newsletter lists.
  static const String newsletterSearchHint = 'Search';

  /// Classroom multi-select placeholder and its inner search placeholder.
  static const String newsletterClassroomFilterHint = 'Classroom';
  static const String newsletterClassroomSearchHint = 'Search classroom';

  // ── Empty and error states ────────────────────────────────────────────────

  /// Parent list, no newsletters for the selected child.
  static const String newsletterNoneParent = 'No Newsletters';

  /// Staff/admin list, nothing sent yet.
  static const String newsletterNoneSent = 'No Sent Newsletters';

  /// Parent list, before a child has been chosen.
  static const String newsletterSelectChild =
      'Select a child to view newsletters.';

  /// Preview screen, the newsletter could not be fetched.
  static const String newsletterLoadFailed = 'Unable to load newsletter.';

  /// Preview screen, the record arrived without a usable code.
  static const String newsletterCodeMissing = 'Newsletter code is missing.';

  /// Preview body, the newsletter has no renderable components.
  static const String newsletterNoContent = 'No newsletter content available.';

  /// Image preview overlay, the image failed to decode.
  static const String newsletterImageLoadFailed = 'Unable to load image';

  /// Sign-in state lost while resolving the school for the list query.
  static const String newsletterSchoolCodeMissing =
      'School code not available. Please sign in again.';

  // ── Hyperlink handling ────────────────────────────────────────────────────

  /// Snackbar when a tapped link has no usable URL.
  static const String newsletterLinkOpenFailed = 'Unable to open link.';

  /// Snackbar when a tapped link could not be launched. The URL is appended.
  static const String newsletterLinkOpenFailedPrefix = 'Unable to open link: ';

  // ── Recipients sheet and card meta ────────────────────────────────────────

  static const String newsletterRecipients = 'Recipients';
  static const String newsletterRecipientsUnavailable =
      'Recipient names are not available.';
  static const String newsletterAttachments = 'Attachments';
  static const String newsletterMetaDate = 'Date';
  static const String newsletterMetaCreatedBy = 'Created by';

  /// Separator between a card meta label and its value. Kept as a constant
  /// because the surrounding spaces are load-bearing.
  static const String newsletterMetaSeparator = ' : ';

  /// Retry action on the newsletter preview's failure state.
  static const String newsletterRetry = 'Retry';

  /// Parent list, a search matched nothing in the whole (fully paged) history.
  static const String newsletterNoSearchMatches =
      'No newsletters match your search.';

  /// Parent list, a search matched nothing YET but more pages are still
  /// loading. Distinct from [newsletterNoSearchMatches] so the user is not
  /// told "nothing found" while the answer is still arriving.
  static const String newsletterSearching = 'Searching…';

  /// Shown to a classroom-scoped staff member when neither their staff profile
  /// nor the classroom list could be loaded, so there is no classroom to scope
  /// the newsletter query by. The alternative would be querying the whole
  /// school, which is what this message exists to prevent.
  static const String newsletterClassroomScopeUnavailable =
      'Unable to load your classrooms. Pull to refresh.';

  /// Classroom label on a card when a newsletter targets every classroom.
  /// Only shown to users who are not classroom-restricted.
  static const String newsletterAllClassrooms = 'All Classrooms';

  /// Singular / plural noun after the recipient count in the sheet header.
  static const String newsletterRecipientSingular = 'recipient';
  static const String newsletterRecipientPlural = 'recipients';

  /// Accessibility label for the image preview barrier.
  static const String newsletterCloseImagePreview = 'Close image preview';

  /// Shown in the "Created by" slot when the API returns an empty
  /// `createdByName`.
  ///
  /// Was the literal `'Demo Test'`, which shipped to real users against real
  /// newsletters. Now `'-'`, which is what the PARENT list already used for
  /// exactly the same case — the two lists disagreed. Aligned on the parent
  /// list's value rather than inventing a third.
  static const String newsletterUnknownAuthor = '-';
}
