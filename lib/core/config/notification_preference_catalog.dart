/// Static catalog mapping each notification-settings **UI row** to the backend
/// notification **definition codes** it controls.
///
/// Why this exists: the 3cdot notification service tracks preferences per
/// `definitionCode` (one per discrete action — see `tools/NOTIFICATION_PAYLOADS.md`),
/// but the settings screen shows a single row for several related actions. The
/// clearest example is **"Students & Staff – …"**: one row, but separate
/// student and staff actions on the backend. So a single toggle must fan out to
/// **all** of that row's definition codes when we PATCH, and the GET response is
/// folded back onto the row.
///
/// These codes are kept **static here for now** (rather than driven purely by the
/// GET response) until the 3cdot definition codes are finalised. When the backend
/// list is confirmed, update [definitionCodes] below — nothing else needs to change.
///
/// Each [title] MUST match the row key used by `NotificationSettingsCubit` and
/// `NotificationSettingsScreen` byte-for-byte (note the non-breaking hyphen `‑`
/// and curly apostrophe `’` in some titles).
class NotificationPreferenceGroup {
  const NotificationPreferenceGroup({
    required this.title,
    required this.categoryName,
    required this.definitionCodes,
  });

  /// Row label shown on the settings screen (matches the cubit matrix key).
  final String title;

  /// Backend category bucket (`categoryName` in the GET response).
  final String categoryName;

  /// One or more `definitionCode`s this single row toggles together.
  final List<String> definitionCodes;
}

/// The source of truth for row ⇄ definition-code grouping.
///
/// NOTE: codes are best-effort placeholders derived from the approved actions in
/// `tools/NOTIFICATION_PAYLOADS.md`. Confirm/replace with the official 3cdot
/// `definitionCode` values before release.
class NotificationPreferenceCatalog {
  NotificationPreferenceCatalog._();

  static const List<NotificationPreferenceGroup> groups =
      <NotificationPreferenceGroup>[
    // ── Messaging ──────────────────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Receive a message from staff',
      categoryName: 'MESSAGING',
      definitionCodes: <String>['MESSAGE_FROM_STAFF'],
    ),
    NotificationPreferenceGroup(
      title: 'Receive a message from parents',
      categoryName: 'MESSAGING',
      definitionCodes: <String>['MESSAGE_FROM_PARENT'],
    ),

    // ── Attendance ─────────────────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Ratio is breached',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>['RATIO_BREACHED', 'CAPACITY_EXCEEDED'],
    ),
    NotificationPreferenceGroup(
      title: 'Student is signed‑in / signed‑out (or marked absent)',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>['STUDENT_SIGN_IN_OUT', 'STUDENT_MARKED_ABSENT'],
    ),
    NotificationPreferenceGroup(
      title: 'Today’s attendance is not marked for Students & Staff',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>['ATTENDANCE_NOT_MARKED'],
    ),

    // ── Newsletter ─────────────────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Newsletter is received',
      categoryName: 'NEWSLETTER',
      definitionCodes: <String>['NEWSLETTER_RECEIVED'],
    ),

    // ── Student / Staff (combined rows fan out to several codes) ────────────
    NotificationPreferenceGroup(
      title: 'Student’s birthday',
      categoryName: 'STUDENT',
      definitionCodes: <String>['STUDENT_BIRTHDATE_NOT_ADDED'],
    ),
    NotificationPreferenceGroup(
      title: 'Students – Immunization (not added, upcoming, expiry/overdue)',
      categoryName: 'STUDENT',
      definitionCodes: <String>['STUDENT_IMMUNIZATION_DUE_OVERDUE'],
    ),
    NotificationPreferenceGroup(
      title:
          'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)',
      categoryName: 'STUDENT_STAFF',
      definitionCodes: <String>[
        'STUDENT_PHYSICAL_NOT_ADDED',
        'STUDENT_PHYSICAL_DUE',
        'STUDENT_PHYSICAL_OVERDUE',
        'STAFF_PHYSICAL_NOT_ADDED',
      ],
    ),
    NotificationPreferenceGroup(
      title: 'Students & Staff – Documents (expiry/overdue)',
      categoryName: 'STUDENT_STAFF',
      definitionCodes: <String>[
        'STUDENT_DOCUMENT_CHANGED',
        'STAFF_DOCUMENT_EXPIRY',
      ],
    ),
    NotificationPreferenceGroup(
      title: 'Students & Staff – Other details (not added, edits)',
      categoryName: 'STUDENT_STAFF',
      definitionCodes: <String>[
        'ADD_STUDENT',
        'DELETE_STUDENT',
        'STUDENT_PARENT_NOT_ADDED',
        'STUDENT_SCHEDULE_NOT_ADDED',
        'DELETE_STAFF',
        'STAFF_SCHEDULE_NOT_ADDED',
      ],
    ),
    NotificationPreferenceGroup(
      title: 'Upcoming student starting the school',
      categoryName: 'STUDENT',
      definitionCodes: <String>['UPCOMING_STUDENT_START'],
    ),

    // ── Scheduling (staff shifts) ──────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Sign‑in alert just after shift start time (if not already done)',
      categoryName: 'SCHEDULING',
      definitionCodes: <String>['STAFF_SIGN_IN_REMINDER'],
    ),
    NotificationPreferenceGroup(
      title: 'Sign‑out alert just after shift end time (if not already done)',
      categoryName: 'SCHEDULING',
      definitionCodes: <String>['STAFF_SIGN_OUT_REMINDER'],
    ),
    NotificationPreferenceGroup(
      title: 'My schedule when published/updated',
      categoryName: 'SCHEDULING',
      definitionCodes: <String>['PUBLISH_SHIFT', 'UPCOMING_SHIFT', 'EDIT_SHIFT'],
    ),
    NotificationPreferenceGroup(
      title: 'Classroom shifts/schedule needs attention',
      categoryName: 'SCHEDULING',
      definitionCodes: <String>['SHIFT_UNDER_RATIO'],
    ),

    // ── Movements (availability) ───────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Upcoming room movements',
      categoryName: 'AVAILABILITY',
      definitionCodes: <String>['UPCOMING_MOVEMENT'],
    ),
    NotificationPreferenceGroup(
      title: 'Overdue room movements',
      categoryName: 'AVAILABILITY',
      definitionCodes: <String>['MOVEMENT_OVERDUE'],
    ),

    // ── Billing ────────────────────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Payment refunded / Failed',
      categoryName: 'BILLING',
      definitionCodes: <String>['PAYMENT_FAILED', 'REFUND_FAILED'],
    ),

    // ── Activity / Incidents ───────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Incident is approved/rejected/acknowledged',
      categoryName: 'ACTIVITIES',
      definitionCodes: <String>[
        'INCIDENT_APPROVAL_PENDING',
        'INCIDENT_ACKNOWLEDGEMENT_PENDING',
      ],
    ),

    // ── Parent persona ─────────────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'My child is signed‑in/signed‑out or marked absent',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>['STUDENT_SIGN_IN_OUT', 'STUDENT_MARKED_ABSENT'],
    ),
    NotificationPreferenceGroup(
      title: 'New activity is recorded for my child',
      categoryName: 'ACTIVITIES',
      definitionCodes: <String>['ACTIVITY_RECORDED'],
    ),
    NotificationPreferenceGroup(
      title: 'Invoice is received',
      categoryName: 'BILLING',
      definitionCodes: <String>['INVOICE_RECEIVED'],
    ),
    NotificationPreferenceGroup(
      title: 'Payment is successful / failed',
      categoryName: 'BILLING',
      definitionCodes: <String>['PAYMENT_SUCCESS', 'PAYMENT_FAILED'],
    ),
    NotificationPreferenceGroup(
      title: 'My child’s profile/details are updated',
      categoryName: 'STUDENT',
      definitionCodes: <String>['STUDENT_DOCUMENT_CHANGED'],
    ),
    NotificationPreferenceGroup(
      title: 'Sign‑in alert just after start time (if not already done)',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>['CHILD_SIGN_IN_REMINDER'],
    ),
    NotificationPreferenceGroup(
      title: 'Sign‑out alert just after end time (if not already done)',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>['CHILD_SIGN_OUT_REMINDER'],
    ),
  ];

  /// Lookup of row title → its group.
  static NotificationPreferenceGroup? byTitle(String title) {
    for (final group in groups) {
      if (group.title == title) return group;
    }
    return null;
  }

  /// Reverse lookup: which row title owns a given definition code.
  /// (First match wins — a code shared by two rows resolves to the first.)
  static String? titleForDefinitionCode(String definitionCode) {
    for (final group in groups) {
      if (group.definitionCodes.contains(definitionCode)) return group.title;
    }
    return null;
  }
}
