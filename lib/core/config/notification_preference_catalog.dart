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
/// Each row also declares the **personas/roles** it belongs to ([roles]). The
/// cubit only sends/reads the rows for the active role, so an ADMIN PATCH never
/// includes parent-only rows (and vice-versa) — which also avoids sending the
/// same `definitionCode` twice from two different rows.
///
/// These codes are kept **static here for now** (rather than driven purely by the
/// GET response) until the 3cdot definition codes are finalised. When the backend
/// list is confirmed, update [definitionCodes] below — nothing else needs to change.
///
/// Each [title] MUST match the row key used by `NotificationSettingsCubit` and
/// `NotificationSettingsScreen` byte-for-byte (note the non-breaking hyphen `‑`
/// and curly apostrophe `’` in some titles).

/// Persona/role tags used by [NotificationPreferenceGroup.roles]. These match the
/// normalized role the cubit resolves (ADMIN | STAFF | GUARDIAN).
abstract final class NotificationRoles {
  static const String admin = 'ADMIN';
  static const String staff = 'STAFF';
  static const String guardian = 'GUARDIAN';

  static const Set<String> all = <String>{admin, staff, guardian};
  static const Set<String> adminStaff = <String>{admin, staff};
  static const Set<String> adminOnly = <String>{admin};
  static const Set<String> guardianOnly = <String>{guardian};
}

class NotificationPreferenceGroup {
  const NotificationPreferenceGroup({
    required this.title,
    required this.categoryName,
    required this.definitionCodes,
    required this.roles,
  });

  /// Row label shown on the settings screen (matches the cubit matrix key).
  final String title;

  /// Backend category bucket (`categoryName` in the GET response).
  final String categoryName;

  /// One or more `definitionCode`s this single row toggles together.
  final List<String> definitionCodes;

  /// Personas/roles this row is shown to (must mirror the screen's visibility).
  final Set<String> roles;
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
      roles: NotificationRoles.all,
    ),
    NotificationPreferenceGroup(
      title: 'Receive a message from parents',
      categoryName: 'MESSAGING',
      definitionCodes: <String>['MESSAGE_FROM_PARENT'],
      roles: NotificationRoles.adminStaff,
    ),

    // ── Attendance ─────────────────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Ratio is breached',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>['RATIO_BREACHED', 'CAPACITY_EXCEEDED'],
      roles: NotificationRoles.adminStaff,
    ),
    NotificationPreferenceGroup(
      title: 'Student is signed‑in / signed‑out (or marked absent)',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>[
        'STUDENT_SIGN_IN_DEF',
        'STUDENT_SIGN_OUT_DEF',
        'STUDENT_MARKED_ABSENT_DEF',
      ],
      roles: NotificationRoles.adminStaff,
    ),
    NotificationPreferenceGroup(
      title: 'Today’s attendance is not marked for Students & Staff',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>[
        'STUD_ATTENDANCE_NOT_MARKED_DEF',
        'STAFF_ATTENDANCE_NOT_MARKED_DEF',
      ],
      roles: NotificationRoles.adminOnly,
    ),

    // ── Newsletter ─────────────────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Newsletter is received',
      categoryName: 'NEWSLETTER',
      definitionCodes: <String>['NEWSLETTER_RECEIVED'],
      roles: NotificationRoles.all,
    ),

    // ── Student / Staff (combined rows fan out to several codes) ────────────
    NotificationPreferenceGroup(
      title: 'Student’s birthday',
      categoryName: 'STUDENT',
      definitionCodes: <String>['STUDENT_BIRTHDATE_NOT_ADDED_DEF'],
      roles: NotificationRoles.adminStaff,
    ),
    NotificationPreferenceGroup(
      title: 'Students – Immunization (not added, upcoming, expiry/overdue)',
      categoryName: 'STUDENT',
      definitionCodes: <String>[
        'STUDENT_IMMUNIZATION_DUE_DEF',
        'STUDENT_IMMUNIZATION_OVERDUE_DEF',
      ],
      roles: NotificationRoles.adminOnly,
    ),
    NotificationPreferenceGroup(
      title:
          'Students & Staff – Physical examination (not added, upcoming, expiry/overdue)',
      categoryName: 'STUDENT_STAFF',
      definitionCodes: <String>[
        'STUDENT_PHYSICAL_NOT_ADDED_DEF',
        'STUDENT_PHYSICAL_DUE_DEF',
        'STUDENT_PHYSICAL_OVERDUE_DEF',
        'STAFF_PHYSICAL_NOT_ADDED_DEF',
        'STAFF_PHYSICAL_DUE_DEF',
        'STAFF_PHYSICAL_OVERDUE_DEF',
      ],
      roles: NotificationRoles.adminOnly,
    ),
    NotificationPreferenceGroup(
      title: 'Students & Staff – Documents (expiry/overdue)',
      categoryName: 'STUDENT_STAFF',
      definitionCodes: <String>[
        'STUDENT_DOCUMENT_ADDED_DEF',
        'STUDENT_DOCUMENT_DELETED_DEF',
        'STUDENT_DOCUMENT_EXPIRY_DEF',
        'STUDENT_DOCUMENT_EXPIRED_DEF',
        'STAFF_DOCUMENT_EXPIRY_DEF',
      ],
      roles: NotificationRoles.adminOnly,
    ),
    NotificationPreferenceGroup(
      title: 'Students & Staff – Other details (not added, edits)',
      categoryName: 'STUDENT_STAFF',
      definitionCodes: <String>[
        'ADD_STUDENT_DEF',
        'DEACTIVATE_STUDENT_DEF',
        'DELETE_STUDENT_DEF',
        'STUDENT_PARENT_NOT_ADDED_DEF',
        'STUDENT_SCHEDULE_NOT_ADDED_DEF',
        'ADD_STAFF_DEF',
        'DEACTIVATE_STAFF_DEF',
        'DELETE_STAFF_DEF',
        'STAFF_SCHEDULE_NOT_ADDED_DEF',
      ],
      roles: NotificationRoles.adminOnly,
    ),
    NotificationPreferenceGroup(
      title: 'Upcoming student starting the school',
      categoryName: 'STUDENT',
      definitionCodes: <String>['UPCOMING_STUDENT_START'],
      roles: NotificationRoles.adminOnly,
    ),

    // ── Scheduling (staff shifts) ──────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Sign‑in alert just after shift start time (if not already done)',
      categoryName: 'SCHEDULING',
      definitionCodes: <String>['STAFF_SIGN_IN_REMINDER'],
      roles: NotificationRoles.adminStaff,
    ),
    NotificationPreferenceGroup(
      title: 'Sign‑out alert just after shift end time (if not already done)',
      categoryName: 'SCHEDULING',
      definitionCodes: <String>['STAFF_SIGN_OUT_REMINDER'],
      roles: NotificationRoles.adminStaff,
    ),
    NotificationPreferenceGroup(
      title: 'My schedule when published/updated',
      categoryName: 'SCHEDULING',
      definitionCodes: <String>[
        'PUBLISH_SHIFT_DEF',
        'UPCOMING_SHIFT_AND_BREAK_DEF',
        'EDIT_SHIFT_DEF',
        'DELETE_SHIFT_DEF',
      ],
      roles: NotificationRoles.adminStaff,
    ),
    NotificationPreferenceGroup(
      title: 'Classroom shifts/schedule needs attention',
      categoryName: 'SCHEDULING',
      definitionCodes: <String>['SCHEDULE_UNDER_RATIO_DEF'],
      roles: NotificationRoles.adminOnly,
    ),

    // ── Movements (availability) ───────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Upcoming room movements',
      categoryName: 'AVAILABILITY',
      definitionCodes: <String>['UPCOMING_MOVEMENT_DEF'],
      roles: NotificationRoles.adminOnly,
    ),
    NotificationPreferenceGroup(
      title: 'Overdue room movements',
      categoryName: 'AVAILABILITY',
      definitionCodes: <String>['MOVEMENT_OVERDUE_DEF'],
      roles: NotificationRoles.adminOnly,
    ),

    // ── Billing ────────────────────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Payment refunded / Failed',
      categoryName: 'BILLING',
      definitionCodes: <String>['PAYMENT_FAILED', 'REFUND_FAILED'],
      roles: NotificationRoles.adminOnly,
    ),

    // ── Activity / Incidents ───────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'Incident is approved/rejected/acknowledged',
      categoryName: 'ACTIVITIES',
      definitionCodes: <String>[
        'INCIDENT_APPROVAL_PENDING',
        'INCIDENT_ACKNOWLEDGEMENT_PENDING',
      ],
      roles: NotificationRoles.adminOnly,
    ),

    // ── Parent persona ─────────────────────────────────────────────────────
    NotificationPreferenceGroup(
      title: 'My child is signed‑in/signed‑out or marked absent',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>[
        'STUDENT_SIGN_IN_DEF',
        'STUDENT_SIGN_OUT_DEF',
        'STUDENT_MARKED_ABSENT_DEF',
      ],
      roles: NotificationRoles.guardianOnly,
    ),
    NotificationPreferenceGroup(
      title: 'New activity is recorded for my child',
      categoryName: 'ACTIVITIES',
      definitionCodes: <String>['ACTIVITY_RECORDED'],
      roles: NotificationRoles.guardianOnly,
    ),
    NotificationPreferenceGroup(
      title: 'Invoice is received',
      categoryName: 'BILLING',
      definitionCodes: <String>['INVOICE_RECEIVED'],
      roles: NotificationRoles.guardianOnly,
    ),
    NotificationPreferenceGroup(
      title: 'Payment is successful / failed',
      categoryName: 'BILLING',
      definitionCodes: <String>['PAYMENT_SUCCESS', 'PAYMENT_FAILED'],
      roles: NotificationRoles.guardianOnly,
    ),
    NotificationPreferenceGroup(
      title: 'My child’s profile/details are updated',
      categoryName: 'STUDENT',
      definitionCodes: <String>['STUDENT_DOCUMENT_CHANGED'],
      roles: NotificationRoles.guardianOnly,
    ),
    NotificationPreferenceGroup(
      title: 'Sign‑in alert just after start time (if not already done)',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>['CHILD_SIGN_IN_REMINDER'],
      roles: NotificationRoles.guardianOnly,
    ),
    NotificationPreferenceGroup(
      title: 'Sign‑out alert just after end time (if not already done)',
      categoryName: 'ATTENDANCE',
      definitionCodes: <String>['CHILD_SIGN_OUT_REMINDER'],
      roles: NotificationRoles.guardianOnly,
    ),
  ];

  /// Groups shown to / sent for the given normalized [role]
  /// (ADMIN | STAFF | GUARDIAN). Unknown/empty role → all groups.
  static List<NotificationPreferenceGroup> groupsForRole(String role) {
    final r = role.trim().toUpperCase();
    if (r.isEmpty) return groups;
    return groups.where((g) => g.roles.contains(r)).toList(growable: false);
  }

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
