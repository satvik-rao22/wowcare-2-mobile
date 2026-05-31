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
  static const String _studentProfileByCode =
      '/dashboard/student-profile-by-code';
  static const String _studentAttendance =
      '/dashboard/student-attendance-tabbed-view';
  static const String _staffAttendance =
      '/dashboard/staff-attendance-tabbed-view';
  static const String _individualMovement = '/dashboard/individual-movement';
  static const String _futureAvailability = '/dashboard/future-availability';

  /// Resolve a notification to its destination, or null when the action is
  /// unknown / has no in-app target.
  static NotificationDestination? resolve(PushNotification n) {
    final action = NotificationAction.canonical(n.action);
    final builder = _table[action];
    if (builder == null) return null;
    return builder(n);
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
  static const _kActivity = ['activityCode', 'activity_code'];

  /// Classroom routes also pre-select the dropdown via `classroomCode` (the
  /// existing ClassroomScreen contract), in addition to `highlightCode`.
  static Map<String, String> _classroomParam(PushNotification n) {
    final c = _firstCode(n, _kClassroom);
    return c == null ? const {} : {'classroomCode': c};
  }

  /// Open a student's profile by code on a specific tab (0 Profile, 1 Health,
  /// 2 Dates, 3 Documents), optionally highlighting a row inside it.
  static NotificationDestination _studentProfile(
    PushNotification n,
    String tab, {
    List<String> highlight = const <String>[],
    String? profileSubTab, // 0 About, 1 Family, 2 Pickup (Profile tab only)
  }) {
    final params = <String, String>{
      'code': _firstCode(n, _kStudent) ?? '',
      'tab': tab,
    };
    if (profileSubTab != null) params['profileTab'] = profileSubTab;
    final hl = _firstCode(n, highlight);
    if (hl != null) params['highlightCode'] = hl;
    return NotificationDestination(
        path: _studentProfileByCode, queryParameters: params);
  }

  static const _kDocument = ['documentCode', 'document_code', 'documentUuid'];

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
    NotificationAction.studentPhysicalNotAdded: (n) => _studentProfile(n, '1'),
    NotificationAction.studentPhysicalDue: (n) => _studentProfile(n, '1'),
    NotificationAction.studentPhysicalOverdue: (n) => _studentProfile(n, '1'),
    NotificationAction.studentImmunizationDueOverdue: (n) =>
        _studentProfile(n, '1'),
    NotificationAction.studentBirthdateNotAdded: (n) =>
        _studentProfile(n, '2'),
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
    NotificationAction.publishShift: (n) =>
        _dest(_scheduling, n, highlight: _kShift),
    NotificationAction.upcomingShift: (n) =>
        _dest(_scheduling, n, highlight: _kShift),
    NotificationAction.shiftUnderRatio: (n) =>
        _dest(_scheduling, n, highlight: _kShift),
    NotificationAction.editShift: (n) =>
        _dest(_scheduling, n, highlight: _kShift),
    NotificationAction.deleteShift: (n) =>
        _dest(_scheduling, n, highlight: _kShift),

    // ── Attendance ───────────────────────────────────────────────────────────
    NotificationAction.ratioBreached: (n) =>
        _dest(_studentAttendance, n, highlight: _kClassroom),
    NotificationAction.studentSignInOut: (n) =>
        _dest(_studentAttendance, n, highlight: _kStudent),
    NotificationAction.studentMarkedAbsent: (n) =>
        _dest(_studentAttendance, n, highlight: _kStudent),
    NotificationAction.attendanceNotMarked: (n) {
      final isStudent = _firstCode(n, _kStudent) != null;
      return isStudent
          ? _dest(_studentAttendance, n, highlight: _kStudent)
          : _dest(_staffAttendance, n, highlight: _kStaff);
    },
    NotificationAction.capacityExceeded: (n) =>
        _dest(_studentAttendance, n, highlight: _kClassroom),

    // ── Activities ───────────────────────────────────────────────────────────
    NotificationAction.activityRecorded: (n) =>
        _dest(AppRoutes.activityFeed, n, highlight: _kActivity),
    NotificationAction.incidentApprovalPending: (n) =>
        _dest(AppRoutes.activityFeed, n, highlight: _kActivity),
    NotificationAction.incidentAcknowledgementPending: (n) =>
        _dest(AppRoutes.activityFeed, n, highlight: _kActivity),
    NotificationAction.napAlert: (n) =>
        _dest(AppRoutes.activityFeed, n, highlight: _kActivity),

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
        const NotificationDestination(path: AppRoutes.messaging),
    NotificationAction.messageToStudent: (n) =>
        const NotificationDestination(path: AppRoutes.messaging),
    NotificationAction.newsletterSent: (n) => const NotificationDestination(
          path: AppRoutes.messaging,
          queryParameters: {'tab': 'newsletter'},
        ),

    // ── Billing (admin → /dashboard/billing, parent → parent billing) ────────
    NotificationAction.invoiceGenerated: (n) =>
        const NotificationDestination(path: _billing),
    NotificationAction.billingPlanChanged: (n) =>
        const NotificationDestination(path: _billing),
    NotificationAction.feeStructureChanged: (n) =>
        const NotificationDestination(path: _billing),
    NotificationAction.invoiceDue: (n) =>
        const NotificationDestination(path: AppRoutes.parentBilling),
    NotificationAction.paymentSuccess: (n) =>
        const NotificationDestination(path: AppRoutes.parentBilling),

    // ── Settings (no settings screen in mobile → stay in notif center) ───────
    NotificationAction.schoolSettingsChanged: (n) =>
        const NotificationDestination(path: '/notifications'),
  };
}
