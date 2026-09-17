/// Canonical set of backend notification `action` values.
///
/// The backend sends one of these verbatim inside the FCM `data` map, e.g.
/// `{action: EDIT_CLASSROOM, type: CLASSROOM, classroomCode: CLS_5739679F-D}`.
///
/// This is the single source of truth for the action vocabulary. The
/// redirection table (`NotificationRouteResolver`) maps each constant to an
/// in-app destination, and the backend keys its notifications off the same
/// strings — so adding a new notification type is: add a constant here, add one
/// row to the resolver table.
///
/// Naming follows `VERB_NOUN` for mutations (`ADD_`/`EDIT_`/`DELETE_`) and
/// `NOUN_STATE` for state/alert events (e.g. `MOVEMENT_OVERDUE`).
class NotificationAction {
  NotificationAction._();

  // ── Classrooms ──────────────────────────────────────────────────────────
  static const String addClassroom = 'ADD_CLASSROOM';
  static const String editClassroom = 'EDIT_CLASSROOM';
  static const String deleteClassroom = 'DELETE_CLASSROOM';
  static const String assignStudentToClassroom = 'ASSIGN_STUDENT_TO_CLASSROOM';
  static const String assignStaffToClassroom = 'ASSIGN_STAFF_TO_CLASSROOM';
  static const String addClassroomNote = 'ADD_CLASSROOM_NOTE';

  // ── Students ────────────────────────────────────────────────────────────
  static const String addStudent = 'ADD_STUDENT';
  static const String deleteStudent = 'DELETE_STUDENT';
  static const String studentParentNotAdded = 'STUDENT_PARENT_NOT_ADDED';
  static const String studentPhysicalNotAdded = 'STUDENT_PHYSICAL_NOT_ADDED';
  static const String studentBirthdateNotAdded = 'STUDENT_BIRTHDATE_NOT_ADDED';
  static const String studentDocumentChanged = 'STUDENT_DOCUMENT_CHANGED';
  static const String studentPhysicalDue = 'STUDENT_PHYSICAL_DUE';
  static const String studentPhysicalOverdue = 'STUDENT_PHYSICAL_OVERDUE';
  static const String studentImmunizationDueOverdue =
      'STUDENT_IMMUNIZATION_DUE_OVERDUE';
  static const String studentScheduleNotAdded = 'STUDENT_SCHEDULE_NOT_ADDED';

  // ── Staff ───────────────────────────────────────────────────────────────
  static const String deleteStaff = 'DELETE_STAFF';
  static const String staffPhysicalNotAdded = 'STAFF_PHYSICAL_NOT_ADDED';
  static const String staffDocumentExpiry = 'STAFF_DOCUMENT_EXPIRY';
  static const String staffScheduleNotAdded = 'STAFF_SCHEDULE_NOT_ADDED';

  // ── Events & To-Dos ─────────────────────────────────────────────────────
  static const String birthday = 'BIRTHDAY';
  static const String upcomingClassroomEvent = 'UPCOMING_CLASSROOM_EVENT';
  static const String upcomingEvent = 'UPCOMING_EVENT';

  // The six `eventTypeCode`s from "Push Notification Payload Contract —
  // Events": `EVENT_INVITED` on create, `EVENT_UPDATED` on update,
  // `EVENT_DELETED` on delete, `EVENT_RSVP_SUBMITTED` on an RSVP, and
  // `EVENT_REMINDER_TOMORROW` / `EVENT_RSVP_REMINDER` fired daily by
  // `EventReminderScheduler`. `EVENT_DELETED` and `EVENT_RSVP_SUBMITTED` are
  // in-app only — no push — per `EVENT_*_DEF.allowedChannels`, but still route
  // a tap on the equivalent inbox item.
  static const String eventInvited = 'EVENT_INVITED';
  static const String eventUpdated = 'EVENT_UPDATED';
  static const String eventDeleted = 'EVENT_DELETED';
  static const String eventReminderTomorrow = 'EVENT_REMINDER_TOMORROW';
  static const String eventRsvpReminder = 'EVENT_RSVP_REMINDER';
  static const String eventRsvpSubmitted = 'EVENT_RSVP_SUBMITTED';

  // ── Tasks ───────────────────────────────────────────────────────────────
  // The six actions the Tasks backend fires, per the push payload contract.
  // Every one carries `taskCode` (the series) + `organizationCode`/
  // `schoolCode`; every action except TASK_DELETED also carries the real
  // `assignmentCode` (added to TASK_ASSIGNED/TASK_UPDATED 2026-08-07 — they
  // used to send only the series). See NotificationRouteResolver —
  // `_taskDetail` reads whichever code is present, falling back to
  // `TasksState.myAssignmentInSeries` (pairing the series with the signed-in
  // user's own identity) when only the series arrives.
  static const String taskAssigned = 'TASK_ASSIGNED';
  static const String taskUpdated = 'TASK_UPDATED';
  static const String taskDeleted = 'TASK_DELETED';
  static const String taskStatusUpdated = 'TASK_STATUS_UPDATED';
  static const String taskOverdue = 'TASK_OVERDUE';
  static const String taskDueSoon = 'TASK_DUE_SOON';

  // ── Holidays ────────────────────────────────────────────────────────────
  // The four actions the Holidays backend fires, per "Push Notification
  // Payload Contract — Holidays". They carry `module: HOLIDAY` (there is no
  // `type: HOLIDAY` key — branch on `action`) plus `holidayName` and, for
  // three of them, a date; `FEDERAL_HOLIDAYS_REVIEW` carries a `year` instead.
  // None carries a holiday entity code, so all four open the Holiday List.
  static const String schoolHolidayCreated = 'SCHOOL_HOLIDAY_CREATED';
  static const String schoolHolidayDeleted = 'SCHOOL_HOLIDAY_DELETED';
  static const String federalHolidayApproved = 'FEDERAL_HOLIDAY_APPROVED';
  static const String federalHolidaysReview = 'FEDERAL_HOLIDAYS_REVIEW';

  // ── Scheduling ──────────────────────────────────────────────────────────
  static const String publishShift = 'PUBLISH_SHIFT';
  static const String upcomingShift = 'UPCOMING_SHIFT';
  static const String shiftUnderRatio = 'SHIFT_UNDER_RATIO';
  static const String editShift = 'EDIT_SHIFT';
  static const String deleteShift = 'DELETE_SHIFT';

  // ── Attendance ──────────────────────────────────────────────────────────
  static const String ratioBreached = 'RATIO_BREACHED';
  static const String studentSignInOut = 'STUDENT_SIGN_IN_OUT';
  static const String studentMarkedAbsent = 'STUDENT_MARKED_ABSENT';
  static const String staffSignInOut = 'STAFF_SIGN_IN_OUT';
  static const String staffMarkedAbsent = 'STAFF_MARKED_ABSENT';
  static const String attendanceNotMarked = 'ATTENDANCE_NOT_MARKED';
  static const String capacityExceeded = 'CAPACITY_EXCEEDED';

  // ── Activities ──────────────────────────────────────────────────────────
  static const String activityRecorded = 'ACTIVITY_RECORDED';
  static const String activityEdited = 'ACTIVITY_EDITED';
  static const String activityDeleted = 'ACTIVITY_DELETED';
  static const String incidentRecorded = 'INCIDENT_RECORDED';
  static const String incidentApprovalPending = 'INCIDENT_APPROVAL_PENDING';
  static const String incidentApproved = 'INCIDENT_APPROVED';
  static const String incidentAcknowledgementPending =
      'INCIDENT_ACKNOWLEDGEMENT_PENDING';
  static const String incidentAcknowledged = 'INCIDENT_ACKNOWLEDGED';
  static const String napAlert = 'NAP_ALERT';

  // ── Availability (room movements) ───────────────────────────────────────
  static const String createRule = 'CREATE_RULE';
  static const String deactivateRule = 'DEACTIVATE_RULE';
  static const String createMovement = 'CREATE_MOVEMENT';
  static const String upcomingMovement = 'UPCOMING_MOVEMENT';
  static const String confirmedMovement = 'CONFIRMED_MOVEMENT';
  static const String movementOverdue = 'MOVEMENT_OVERDUE';
  static const String movementRejected = 'MOVEMENT_REJECTED';

  // ── Communication ───────────────────────────────────────────────────────
  static const String messageToStaff = 'MESSAGE_TO_STAFF';
  static const String messageToStudent = 'MESSAGE_TO_STUDENT';
  static const String newsletterSent = 'NEWSLETTER_SENT';

  // ── Billing ─────────────────────────────────────────────────────────────
  static const String invoiceGenerated = 'INVOICE_GENERATED';
  static const String invoiceDue = 'INVOICE_DUE';
  static const String paymentSuccess = 'PAYMENT_SUCCESS';
  static const String billingPlanChanged = 'BILLING_PLAN_CHANGED';
  static const String feeStructureChanged = 'FEE_STRUCTURE_CHANGED';

  // ── Settings ────────────────────────────────────────────────────────────
  static const String schoolSettingsChanged = 'SCHOOL_SETTINGS_CHANGED';

  // ── Geofence (device-local, fired by native geofence on enter) ───────────
  static const String geofenceEnter = 'GEOFENCE_ENTER';

  /// Backend variants that should be treated as a known action above.
  static const Map<String, String> aliases = <String, String>{
    'CREATE_CLASSROOM': addClassroom,
    'EDIT_STUDENT': addStudent, // edits land on the student list, highlighted
    'EDIT_STAFF': deleteStaff, // (DELETE_* here just means "staff list" target)
    // Inbox event types are granular / prefixed; map them onto the combined
    // canonical actions the redirection table is keyed by.
    // Attendance
    'STUDENT_SIGN_IN': studentSignInOut,
    'STUDENT_SIGN_OUT': studentSignInOut,
    'STAFF_SIGN_IN': staffSignInOut,
    'STAFF_SIGN_OUT': staffSignInOut,
    'CLASSROOM_RATIO_BREACHED': ratioBreached,
    'CLASSROOM_CAPACITY_EXCEEDED': capacityExceeded,
    'STUD_ATTENDANCE_NOT_MARKED': attendanceNotMarked,
    'STAFF_ATTENDANCE_NOT_MARKED': attendanceNotMarked,
    // Classroom
    'DEACTIVATE_CLASSROOM': deleteClassroom,
    // Student
    'DEACTIVATE_STUDENT': deleteStudent,
    'STUDENT_IMMUNIZATION_DUE': studentImmunizationDueOverdue,
    'STUDENT_IMMUNIZATION_OVERDUE': studentImmunizationDueOverdue,
    'STUDENT_DOCUMENT_ADDED': studentDocumentChanged,
    'STUDENT_DOCUMENT_DELETED': studentDocumentChanged,
    'STUDENT_DOCUMENT_EXPIRY': studentDocumentChanged,
    'STUDENT_DOCUMENT_EXPIRED': studentDocumentChanged,
    // Staff
    'ADD_STAFF': deleteStaff, // staff list target
    'DEACTIVATE_STAFF': deleteStaff,
    'STAFF_PHYSICAL_DUE': staffPhysicalNotAdded, // staff profile → physical tab
    'STAFF_PHYSICAL_OVERDUE': staffPhysicalNotAdded,
    // Scheduling
    'UPCOMING_SHIFT_AND_BREAK': upcomingShift,
    'SCHEDULE_UNDER_RATIO': shiftUnderRatio,
    // Movements
    'DELETE_RULE': deactivateRule,
    // Messaging / newsletter
    'MESSAGE_FROM_STAFF': messageToStaff,
    'MESSAGE_FROM_PARENT': messageToStudent,
    'NEWSLETTER_RECEIVED': newsletterSent,
    // Activities/incidents — backend's actual event-type strings differ from
    // this file's older constant spellings (e.g. NAP_REMINDER vs NAP_ALERT,
    // INCIDENT_ACK_PENDING vs INCIDENT_ACKNOWLEDGEMENT_PENDING), so without
    // these aliases those pushes fell through to the module fallback (or, for
    // INCIDENT_RECORDED specifically, matched nothing at all) and the tap
    // did nothing.
    'NAP_REMINDER': napAlert,
    'INCIDENT_ACK_PENDING': incidentAcknowledgementPending,
    // Task action names this app shipped with, superseded by the contract's
    // TASK_* set above. Kept so an older backend build still routes.
    'ASSIGN_TASK': taskAssigned,
    'TASK_DUE': taskDueSoon,
  };

  /// Normalises a raw backend action to its canonical constant.
  static String canonical(String? raw) {
    final a = (raw ?? '').trim().toUpperCase();
    return aliases[a] ?? a;
  }
}
