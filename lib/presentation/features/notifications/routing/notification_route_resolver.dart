import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/src/app_router.dart';

import '../../../../domain/features/notifications/entities/notification_action.dart';
import '../../../../domain/features/notifications/entities/push_notification.dart';

/// Where a tapped notification should take the user, expressed as a go_router
/// location plus an optional `highlightCode`.
///
/// **Highlight convention:** any destination that targets a specific row sets
/// [highlightCode] (the studentCode / documentCode / shift_code / …). The
/// destination screen reads it from `state.uri.queryParameters['highlightCode']`
/// and hands it down to [HighlightableCard], which scrolls to and flashes the
/// matching card.
class NotificationDestination {
  const NotificationDestination({
    required this.path,
    this.queryParameters = const <String, String>{},
  });

  final String path;
  final Map<String, String> queryParameters;

  static const String highlightParam = 'highlightCode';

  /// The go_router location string, e.g. `/classroom-screen?classroomCode=CLS_1`.
  String get location => Uri(
        path: path,
        queryParameters:
            queryParameters.isEmpty ? null : queryParameters,
      ).toString();
}

/// Pure, widget-free mapping from a backend notification action to its in-app
/// destination. This is the **single dedicated action→redirection table** — to
/// support a new notification, add a constant in [NotificationAction] and one
/// row in [_table] here. Nothing else changes.
///
/// Kept free of any Flutter/router runtime dependency (only `AppRoutes`
/// constants) so it can be unit-tested in isolation and the View layer
/// ([NotificationNavigator]) stays a thin `resolve → appRouter.go` glue.
class NotificationRouteResolver {
  NotificationRouteResolver._();

  // Dashboard-nested child paths (not exposed on AppRoutes). Kept here as the
  // routing table's private vocabulary.
  static const String _students = '/dashboard/students';
  static const String _staff = '/dashboard/staff';
  static const String _billing = '/dashboard/billing';
  static const String _scheduling = '/dashboard/scheduling';
  static const String _staffScheduling = '/dashboard/staff-scheduling';
  static const String _studentProfileByCode =
      '/dashboard/student-profile-by-code';
  static const String _individualMovement = '/dashboard/individual-movement';
  static const String _futureAvailability = '/dashboard/future-availability';
  static const String _classroomInfo = '/dashboard/classroom-info-screen';
  static const String _studentAttendanceProfileByCode =
      '/dashboard/student-attendance-profile-by-code';
  static const String _staffAttendanceProfileByCode =
      '/dashboard/staff-attendance-profile-by-code';

  /// Resolve a notification to its destination, or null when the action is
  /// unknown / has no in-app target.
  ///
  /// [isGuardian] is the **current user's** persona at tap time. Billing actions
  /// open a different screen per persona (guardians → parent billing; staff /
  /// admins → the dashboard billing screen), which the action string alone can't
  /// express — so the caller passes the resolved persona in.
  static NotificationDestination? resolve(
    PushNotification n, {
    bool isGuardian = false,
  }) {
    final action = NotificationAction.canonical(n.action);

    // Billing is persona-routed (see [_billingActions]). Guardians land on the
    // parent billing screen, everyone else on the admin/dashboard billing
    // screen. `invoiceCode` rides along as `highlightCode` so the row can be
    // flashed once per-invoice highlighting is wired on the billing screens.
    if (_billingActions.contains(action)) {
      return _dest(
        isGuardian ? AppRoutes.parentBilling : _billing,
        n,
        highlight: _kInvoice,
      );
    }

    final builder = _table[action];
    if (builder != null) return builder(n);

    // Fallback: no exact action match, so land on the notification's MODULE
    // (category) home screen instead of doing nothing. Keeps every inbox item
    // tappable even when its precise event type isn't in the table yet.
    return _moduleFallback(n, isGuardian: isGuardian);
  }

  /// Routes by the notification's `module`/category to a sensible landing
  /// screen. Returns null only when the module is unknown (tap stays put).
  static NotificationDestination? _moduleFallback(
    PushNotification n, {
    required bool isGuardian,
  }) {
    final module =
        (n.data['module'] ?? n.data['categoryCode'] ?? n.type ?? '')
            .trim()
            .toUpperCase();
    switch (module) {
      case 'CLASSROOM':
      case 'CLASSROOM_SCHEDULE':
        return _dest(AppRoutes.classroom, n,
            highlight: _kClassroom, params: _classroomParam(n));
      case 'STUDENT':
        return _dest(_students, n, highlight: _kStudent);
      case 'STAFF':
        return _dest(_staff, n, highlight: _kStaff);
      case 'ATTENDANCE':
      case 'STUDENT_ATTENDANCE':
      case 'STAFF_ATTENDANCE':
        if (_firstCode(n, _kStudent) != null) return _studentAttendanceProfile(n);
        if (_firstCode(n, _kStaff) != null) return _staffAttendanceProfile(n);
        return const NotificationDestination(path: AppRoutes.dashboard);
      case 'SCHEDULING':
      case 'STAFF_SCHEDULING':
        return _staffShift(n);
      case 'AVAILABILITY':
      case 'FUTURE_AVAILABILITY':
      case 'MOVEMENT_RULE':
      case 'MOVEMENT_RULES':
      case 'INDIVIDUAL_MOVEMENT':
      case 'INDIVISUAL_MOVEMENTS':
        return _dest(_individualMovement, n, highlight: _kMovement);
      case 'BILLING':
      case 'ACCOUNTS':
      case 'INVOICES':
      case 'TRANSACTION':
        return _dest(isGuardian ? AppRoutes.parentBilling : _billing, n,
            highlight: _kInvoice);
      case 'ACTIVITIES':
      case 'DAILY_ACTIVITY':
        return _dest(AppRoutes.activityFeed, n,
            highlight: _kActivity, params: _activityParams(n));
      case 'PARENT_MESSAGING':
        // Room-chat / parent messaging → Parent Messaging (Room Chats) sub-tab.
        return const NotificationDestination(
          path: AppRoutes.messaging,
          queryParameters: {'msgTab': 'parent'},
        );
      case 'STAFF_MESSAGING':
        // A staff-to-staff message → Staff Messaging sub-tab (the module now defaults to Parent).
        return const NotificationDestination(
          path: AppRoutes.messaging,
          queryParameters: {'msgTab': 'staff'},
        );
      case 'MESSAGING':
      case 'NEWSLETTER':
        return const NotificationDestination(path: AppRoutes.messaging);
      default:
        return null;
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  /// First non-empty value among [keys] in the payload (handles camelCase /
  /// snake_case variants the backend may send).
  static String? _firstCode(PushNotification n, List<String> keys) {
    for (final k in keys) {
      final v = n.data[k]?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Build a destination, attaching `highlightCode` from the first matching
  /// payload key and merging any [params] the target route needs.
  static NotificationDestination _dest(
    String path,
    PushNotification n, {
    List<String> highlight = const <String>[],
    Map<String, String> params = const <String, String>{},
  }) {
    final query = <String, String>{...params};
    final code = _firstCode(n, highlight);
    if (code != null) query[NotificationDestination.highlightParam] = code;
    return NotificationDestination(path: path, queryParameters: query);
  }

  // Common payload-key groups. Backend always sends a single `...Code`
  // (singular) — never a plural `...Codes`.
  static const _kClassroom = ['classroomCode', 'classroom_code'];
  static const _kStudent = ['studentCode', 'student_code'];
  static const _kStaff = ['staffCode', 'staff_code'];
  static const _kShift = ['shift_code', 'shiftCode'];
  // Movement cards match by integer id, so prefer `movement_id` for highlight.
  static const _kMovement = ['movement_id', 'movement_code', 'movementCode'];
  /// Activity feed CARDS are keyed by `cardGroupCode` — see
  /// `ActivityFeedModels`, which resolves a row's code as
  /// `cardGroupCode ?? code ?? batchGroupCode ?? activityCode`. A card groups
  /// the per-student activity rows, so the notification's `activityCode`
  /// (ACT_…) never equals the rendered card's code (ACG_…) and the highlight
  /// silently no-ops. Prefer the group code and keep `activityCode` as the
  /// fallback for payloads/rows that only carry it.
  static const _kActivity = [
    'cardGroupCode',
    'card_group_code',
    'batchGroupCode',
    'batch_group_code',
    'activityCode',
    'activity_code',
  ];
  static const _kInvoice = ['invoiceCode', 'invoice_code'];

  /// Billing actions are routed by the current user's persona in [resolve]
  /// (guardian → parent billing, staff/admin → dashboard billing) rather than by
  /// a fixed entry in [_table].
  static const Set<String> _billingActions = <String>{
    NotificationAction.invoiceGenerated,
    NotificationAction.invoiceDue,
    NotificationAction.paymentSuccess,
    NotificationAction.billingPlanChanged,
    NotificationAction.feeStructureChanged,
  };

  /// Classroom routes also pre-select the dropdown via `classroomCode` (the
  /// existing ClassroomScreen contract), in addition to `highlightCode`.
  static Map<String, String> _classroomParam(PushNotification n) {
    final c = _firstCode(n, _kClassroom);
    return c == null ? const {} : {'classroomCode': c};
  }

  /// Activity date (`date`/`activityDate` payload key) → `date=yyyy-MM-dd` so the
  /// Activity Feed opens on the activity's day, where its card can be flashed.
  /// Payload keys carrying the activity's timestamp. The backend sends
  /// `activityMarkedDate` for ACTIVITY_RECORDED / nap / incident events — it was
  /// missing here, so no `date` param was produced and the feed opened on
  /// *today* instead of the activity's day, leaving no card to highlight.
  static const _kActivityDate = [
    'date',
    'activityDate',
    'activity_date',
    'activityMarkedDate',
    'activity_marked_date',
    // Last resort: older ACTIVITY notifications carry no date field at all
    // (they predate `activityMarkedDate`), so fall back to when the inbox item
    // was created — see AppNotificationModel.fromInboxJson. Without this a tap
    // on an older notification opens the feed on TODAY instead of the day the
    // activity happened.
    'notificationCreatedAt',
  ];

  /// Query params an activity deep-link needs so the feed actually contains the
  /// target card: its day AND its classroom. The feed loads a single classroom
  /// at a time (defaulting to the viewer's primary room), so without the
  /// classroom an activity in any other room simply isn't in the list and the
  /// highlight silently no-ops.
  static Map<String, String> _activityParams(PushNotification n) => {
        ..._activityDateParam(n),
        ..._classroomParam(n),
      };

  static Map<String, String> _activityDateParam(PushNotification n) {
    final raw = _firstCode(n, _kActivityDate) ?? '';
    if (raw.isEmpty) return const {};
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return {'date': raw};
    // The payload carries a UTC instant (e.g. 2026-07-22T14:53:00Z) but the
    // feed's day selector works in the SCHOOL calendar. Taking the raw UTC
    // y/m/d can land a day off for schools far from UTC — again opening a feed
    // that doesn't contain the card. Non-UTC values (a bare `yyyy-MM-dd`) are
    // already calendar dates, so use them as-is.
    final ymd = parsed.isUtc
        ? SchoolZoneDateTime.yyyyMmDdFromUtcInstant(
            parsed,
            SchoolTimezoneResolver.lastKnownTimeZone,
          )
        : '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    return {'date': ymd};
  }

  static const _kShiftDate = ['shiftDate', 'shift_date'];
  static const _kBlockDate = ['blockDate', 'block_date'];

  /// Normalises the first non-empty date among [keys] to `yyyy-MM-dd`, or null.
  static String? _ymd(PushNotification n, List<String> keys) {
    final raw = _firstCode(n, keys);
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.length >= 10 ? raw.substring(0, 10) : raw;
    return '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
  }

  /// Shift notifications (publish/upcoming/edit/delete) open the per-staff Staff
  /// Scheduling day view: jump to the shift's day, select its staff member, and
  /// flash the shift block (`highlightCode` = shiftCode).
  static NotificationDestination _staffShift(PushNotification n) {
    final query = <String, String>{};
    final date = _ymd(n, _kShiftDate);
    if (date != null) query['date'] = date;
    final staff = _firstCode(n, _kStaff);
    if (staff != null) query['staffCode'] = staff;
    final shift = _firstCode(n, _kShift);
    if (shift != null) query[NotificationDestination.highlightParam] = shift;
    return NotificationDestination(path: _staffScheduling, queryParameters: query);
  }

  /// SHIFT_UNDER_RATIO opens the main Scheduling screen forced into DAY view on
  /// the block's date and flashes the under-ratio classroom block
  /// (`highlightCode` = classroomCode — under-ratio blocks carry no shift code).
  static NotificationDestination _shiftUnderRatio(PushNotification n) {
    final query = <String, String>{'view': 'day'};
    final date = _ymd(n, _kBlockDate);
    if (date != null) query['date'] = date;
    final classroom = _firstCode(n, _kClassroom);
    if (classroom != null) {
      query[NotificationDestination.highlightParam] = classroom;
    }
    return NotificationDestination(path: _scheduling, queryParameters: query);
  }

  /// Open a student's profile by code on a specific tab (0 Profile, 1 Health,
  /// 2 Dates, 3 Documents), optionally highlighting a row inside it.
  static NotificationDestination _studentProfile(
    PushNotification n,
    String tab, {
    List<String> highlight = const <String>[],
    String? profileSubTab, // 0 About, 1 Family, 2 Pickup (Profile tab only)
    String? healthSubTab, // 0 Health, 1 Physician, 2 Physical Dates, 3 Immun.
  }) {
    final params = <String, String>{
      'code': _firstCode(n, _kStudent) ?? '',
      'tab': tab,
    };
    if (profileSubTab != null) params['profileTab'] = profileSubTab;
    if (healthSubTab != null) params['healthTab'] = healthSubTab;
    final hl = _firstCode(n, highlight);
    if (hl != null) params['highlightCode'] = hl;
    return NotificationDestination(
        path: _studentProfileByCode, queryParameters: params);
  }

  static const _kDocument = [
    'documentCode',
    'document_code',
    'documentUuid',
    'document_uuid',
    // Backend payload currently sends this MISSPELLED key (missing the 'n') for
    // student-document notifications, e.g. {"documetCode":"DOC_…"}. Tolerate it
    // so the document row still highlights. Remove once the backend fixes it.
    'documetCode',
    'documet_code',
  ];

  static const String _staffProfileByCode = '/dashboard/staff-profile-by-code';

  /// Open a staff profile by code on a specific tab (0 Profile, 1 Dates,
  /// 2 Documents), optionally highlighting a row inside it.
  static NotificationDestination _staffProfile(
    PushNotification n,
    String tab, {
    List<String> highlight = const <String>[],
  }) {
    final params = <String, String>{
      'code': _firstCode(n, _kStaff) ?? '',
      'tab': tab,
    };
    final hl = _firstCode(n, highlight);
    if (hl != null) params['highlightCode'] = hl;
    return NotificationDestination(
        path: _staffProfileByCode, queryParameters: params);
  }

  /// Open a student's ATTENDANCE profile by code (self-loads identity + data).
  static NotificationDestination _studentAttendanceProfile(PushNotification n) =>
      NotificationDestination(
        path: _studentAttendanceProfileByCode,
        queryParameters: {'code': _firstCode(n, _kStudent) ?? ''},
      );

  /// Open a staff member's ATTENDANCE profile by code.
  static NotificationDestination _staffAttendanceProfile(PushNotification n) =>
      NotificationDestination(
        path: _staffAttendanceProfileByCode,
        queryParameters: {'code': _firstCode(n, _kStaff) ?? ''},
      );

  static final Map<String, NotificationDestination Function(PushNotification)>
      _table = <String, NotificationDestination Function(PushNotification)>{
    // ── Classrooms ──────────────────────────────────────────────────────────
    NotificationAction.addClassroom: (n) => _dest(AppRoutes.classroom, n,
        highlight: _kClassroom, params: _classroomParam(n)),
    NotificationAction.editClassroom: (n) => _dest(AppRoutes.classroom, n,
        highlight: _kClassroom, params: _classroomParam(n)),
    NotificationAction.deleteClassroom: (n) => _dest(AppRoutes.classroom, n,
        highlight: _kClassroom, params: _classroomParam(n)),
    // Assign actions open the relevant tab (0 students / 1 staff / 2 notes)
    // and highlight the assigned row inside it.
    NotificationAction.assignStudentToClassroom: (n) => _dest(
        AppRoutes.classroom, n,
        highlight: _kStudent,
        params: {..._classroomParam(n), 'tab': '0'}),
    NotificationAction.assignStaffToClassroom: (n) => _dest(
        AppRoutes.classroom, n,
        highlight: _kStaff,
        params: {..._classroomParam(n), 'tab': '1'}),
    NotificationAction.addClassroomNote: (n) => _dest(AppRoutes.classroom, n,
        highlight: _kClassroom,
        params: {..._classroomParam(n), 'tab': '2'}),

    // ── Students (land on the student list, highlighting the student) ────────
    NotificationAction.addStudent: (n) =>
        _dest(_students, n, highlight: _kStudent),
    NotificationAction.deleteStudent: (n) =>
        _dest(_students, n, highlight: _kStudent),
    // Profile sub-actions open the student's profile on the relevant tab.
    // "Parent not added" lands on the Profile tab's Family sub-tab (1).
    NotificationAction.studentParentNotAdded: (n) =>
        _studentProfile(n, '0', profileSubTab: '1'),
    NotificationAction.studentScheduleNotAdded: (n) => _studentProfile(n, '0'),
    // Physical alerts open Health → "Physical Examination Dates" sub-tab (2).
    NotificationAction.studentPhysicalNotAdded: (n) =>
        _studentProfile(n, '1', healthSubTab: '2'),
    NotificationAction.studentPhysicalDue: (n) =>
        _studentProfile(n, '1', healthSubTab: '2'),
    NotificationAction.studentPhysicalOverdue: (n) =>
        _studentProfile(n, '1', healthSubTab: '2'),
    // Immunization alerts open Health → "Immunization" sub-tab (3).
    NotificationAction.studentImmunizationDueOverdue: (n) =>
        _studentProfile(n, '1', healthSubTab: '3'),
    // "Birthdate not added" lands on the Profile tab's About sub-tab (0), where
    // the Birth Date field lives.
    NotificationAction.studentBirthdateNotAdded: (n) =>
        _studentProfile(n, '0'),
    NotificationAction.studentDocumentChanged: (n) =>
        _studentProfile(n, '3', highlight: _kDocument),

    // ── Staff ────────────────────────────────────────────────────────────────
    NotificationAction.deleteStaff: (n) =>
        _dest(_staff, n, highlight: _kStaff),
    NotificationAction.staffScheduleNotAdded: (n) => _staffProfile(n, '0'),
    NotificationAction.staffPhysicalNotAdded: (n) => _staffProfile(n, '1'),
    NotificationAction.staffDocumentExpiry: (n) =>
        _staffProfile(n, '2', highlight: _kDocument),

    // ── Events & To-Dos (birthday targets the relevant person list) ──────────
    NotificationAction.birthday: (n) {
      final hasStudent = _firstCode(n, _kStudent) != null;
      // Birthday lives on the Dates tab (student tab 2 / staff tab 1).
      return hasStudent ? _studentProfile(n, '2') : _staffProfile(n, '1');
    },
    NotificationAction.upcomingClassroomEvent: (n) =>
        const NotificationDestination(path: AppRoutes.dashboard),
    NotificationAction.upcomingEvent: (n) =>
        const NotificationDestination(path: AppRoutes.dashboard),
    NotificationAction.assignTask: (n) =>
        const NotificationDestination(path: AppRoutes.dashboard),
    NotificationAction.taskDue: (n) =>
        const NotificationDestination(path: AppRoutes.dashboard),
    NotificationAction.taskOverdue: (n) =>
        const NotificationDestination(path: AppRoutes.dashboard),

    // ── Scheduling ───────────────────────────────────────────────────────────
    // Shift mutations open the per-staff Staff Scheduling day view (jump to the
    // shift's day, select its staff, flash the shift block).
    NotificationAction.publishShift: (n) => _staffShift(n),
    NotificationAction.upcomingShift: (n) => _staffShift(n),
    NotificationAction.editShift: (n) => _staffShift(n),
    NotificationAction.deleteShift: (n) => _staffShift(n),
    // Under-ratio opens the main Scheduling day view, flashing the classroom.
    NotificationAction.shiftUnderRatio: (n) => _shiftUnderRatio(n),

    // ── Attendance ───────────────────────────────────────────────────────────
    // Ratio breached opens the Classroom Info screen for that classroom.
    NotificationAction.ratioBreached: (n) =>
        _dest(_classroomInfo, n, params: _classroomParam(n)),
    // Sign-in/out & marked-absent open the person's ATTENDANCE PROFILE screen.
    NotificationAction.studentSignInOut: (n) => _studentAttendanceProfile(n),
    NotificationAction.studentMarkedAbsent: (n) => _studentAttendanceProfile(n),
    NotificationAction.staffSignInOut: (n) => _staffAttendanceProfile(n),
    NotificationAction.staffMarkedAbsent: (n) => _staffAttendanceProfile(n),
    // Attendance not marked opens the person's attendance PROFILE screen
    // (student or staff), which self-loads its data by code.
    NotificationAction.attendanceNotMarked: (n) =>
        _firstCode(n, _kStudent) != null
            ? _studentAttendanceProfile(n)
            : _staffAttendanceProfile(n),
    // Capacity exceeded opens the Classroom Info screen for that classroom.
    NotificationAction.capacityExceeded: (n) =>
        _dest(_classroomInfo, n, params: _classroomParam(n)),

    // ── Activities (open the Activity Feed on the activity's date + flash it) ──
    NotificationAction.activityRecorded: (n) => _dest(AppRoutes.activityFeed, n,
        highlight: _kActivity, params: _activityParams(n)),
    NotificationAction.incidentApprovalPending: (n) => _dest(
        AppRoutes.activityFeed, n,
        highlight: _kActivity, params: _activityParams(n)),
    NotificationAction.incidentAcknowledgementPending: (n) => _dest(
        AppRoutes.activityFeed, n,
        highlight: _kActivity, params: _activityParams(n)),
    NotificationAction.napAlert: (n) => _dest(AppRoutes.activityFeed, n,
        highlight: _kActivity, params: _activityParams(n)),

    // ── Availability (room movements) ────────────────────────────────────────
    NotificationAction.createRule: (n) =>
        const NotificationDestination(path: _futureAvailability),
    NotificationAction.deactivateRule: (n) =>
        const NotificationDestination(path: _futureAvailability),
    NotificationAction.createMovement: (n) =>
        _dest(_individualMovement, n, highlight: _kMovement),
    NotificationAction.upcomingMovement: (n) =>
        _dest(_individualMovement, n, highlight: _kMovement),
    NotificationAction.confirmedMovement: (n) =>
        _dest(_individualMovement, n, highlight: _kMovement),
    NotificationAction.movementOverdue: (n) =>
        _dest(_individualMovement, n, highlight: _kMovement),
    NotificationAction.movementRejected: (n) =>
        _dest(_individualMovement, n, highlight: _kMovement),

    // ── Communication ────────────────────────────────────────────────────────
    NotificationAction.messageToStaff: (n) =>
        // A staff-to-staff message → Staff Messaging sub-tab (the module now defaults to Parent).
        const NotificationDestination(
          path: AppRoutes.messaging,
          queryParameters: {'msgTab': 'staff'},
        ),
    NotificationAction.messageToStudent: (n) =>
        // MESSAGE_FROM_PARENT = a room-chat/parent message → open the Parent Messaging
        // (Room Chats) sub-tab, not Staff Messaging (which is index 0 = the default).
        const NotificationDestination(
          path: AppRoutes.messaging,
          queryParameters: {'msgTab': 'parent'},
        ),
    NotificationAction.newsletterSent: (n) => const NotificationDestination(
          path: AppRoutes.messaging,
          queryParameters: {'tab': 'newsletter'},
        ),

    // ── Billing ──────────────────────────────────────────────────────────────
    // Persona-routed in [resolve] (guardian → parent billing, staff/admin →
    // dashboard billing), so the billing actions are intentionally NOT in this
    // table. See [_billingActions].

    // ── Settings (no settings screen in mobile → stay in notif center) ───────
    NotificationAction.schoolSettingsChanged: (n) =>
        const NotificationDestination(path: '/notifications'),

    // ── Geofence (native enter tap → open dashboard where sign-in card lives) ─
    NotificationAction.geofenceEnter: (n) =>
        const NotificationDestination(path: AppRoutes.dashboard),
  };
}
