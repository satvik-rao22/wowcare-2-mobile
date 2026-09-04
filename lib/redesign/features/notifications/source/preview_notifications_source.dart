import 'dart:async';

import 'package:wowcare/domain/features/notifications/entities/notification_action.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';
import 'package:wowcare/redesign/features/notifications/source/notifications_source.dart';

/// Which answer the fixtures give, so every state 12b draws is reachable by
/// changing one line in `notifications_di.dart`.
enum PreviewNotificationsMode {
  /// The inbox, twenty-six deep.
  ready,

  /// An account nothing has ever arrived for.
  empty,

  /// Every read throws: 12b's "couldn't load", with nothing to fall back on.
  failed,

  /// The first read lands and every later one throws, which is the offline
  /// banner over a list that is still worth reading.
  offline,

  /// [ready], and then a push arrives a few seconds after the first page.
  arriving,
}

/// M12's fixtures: two days of Maple View's inbox on the design's own day.
///
/// The people are `DemoData`'s and the copy is the design's own feed, so the
/// incident awaiting approval is in the Sunflower the dashboard counts, and
/// the invoice is to the family whose children are on that roster.
///
/// Scoping is done here rather than in the cubit because that is where it
/// really happens: the server decides what a role may be told about before it
/// reaches the phone (12e). An admin sees the school, a staff member sees the
/// classroom they are rostered to and their own record, and a guardian sees
/// their children, their money and what was written to them.
class PreviewNotificationsSource implements NotificationsSource {
  PreviewNotificationsSource({this.mode = PreviewNotificationsMode.ready});

  final PreviewNotificationsMode mode;

  /// Long enough that the skeleton is seen, short enough to stay out of the
  /// way.
  static const Duration _latency = Duration(milliseconds: 400);

  /// How long after the first page a push lands in [PreviewNotificationsMode.arriving].
  static const Duration _arrivalDelay = Duration(seconds: 4);

  /// The classroom Dana Whitfield is rostered to, which is the staff scope.
  static const String _staffClassroom = 'Sunflower';

  /// The guardian's children, by student id.
  static const Set<String> _guardianChildren = <String>{'amara', 'sam'};

  final StreamController<void> _arrivals = StreamController<void>.broadcast();

  final Set<String> _readIds = <String>{};
  bool _allRead = false;
  bool _hasLoaded = false;
  bool _hasArrived = false;
  Timer? _arrival;

  @override
  Stream<void> get arrivals => _arrivals.stream;

  /// Fixture housekeeping: closes the arrival signal and drops the pending
  /// push. Wired to the locator's own dispose, and gone in Phase 5.
  void dispose() {
    _arrival?.cancel();
    _arrival = null;
    unawaited(_arrivals.close());
  }

  @override
  Future<NotificationFeed> loadPage({
    required Persona persona,
    required int page,
    required int pageSize,
    NotificationFilter filter = NotificationFilter.all,
    bool onlyUnread = false,
  }) async {
    await Future<void>.delayed(_latency);

    if (mode == PreviewNotificationsMode.failed) {
      throw const NotificationsUnavailable();
    }
    if (mode == PreviewNotificationsMode.offline && _hasLoaded) {
      throw const NotificationsUnavailable();
    }
    _scheduleArrival();
    _hasLoaded = true;

    if (mode == PreviewNotificationsMode.empty) {
      return NotificationFeed(asOf: DemoData.today);
    }

    final scoped = <NotificationItem>[
      for (final row in _rows)
        if (row.reaches(persona)) row.item(read: _isRead(row)),
    ];
    final matching = <NotificationItem>[
      for (final item in scoped)
        if (filter.matches(item.module) && (!onlyUnread || !item.isRead)) item,
    ];

    final start = page * pageSize;
    final end = start + pageSize;
    return NotificationFeed(
      asOf: DemoData.today,
      items: start >= matching.length
          ? const <NotificationItem>[]
          : matching.sublist(start, end.clamp(0, matching.length)),
      hasMore: end < matching.length,
      // The total that spans every page, which is what the bell shows.
      unreadCount: scoped.where((i) => !i.isRead).length,
    );
  }

  @override
  Future<void> markRead(String id) async {
    await Future<void>.delayed(_latency);
    _readIds.add(id);
  }

  @override
  Future<void> markAllRead() async {
    await Future<void>.delayed(_latency);
    _allRead = true;
  }

  bool _isRead(_Row row) => _allRead || row.isRead || _readIds.contains(row.id);

  /// One push, once, and only in the mode that asks for it.
  void _scheduleArrival() {
    if (mode != PreviewNotificationsMode.arriving) return;
    if (_hasLoaded || _arrival != null) return;
    _arrival = Timer(_arrivalDelay, () {
      _hasArrived = true;
      if (!_arrivals.isClosed) _arrivals.add(null);
    });
  }

  // --- The feed -------------------------------------------------------------

  /// Newest first, as the inbox returns it. Seven of the twenty-six are
  /// unread, which is the count the app's own bell fixture carries.
  List<_Row> get _rows => <_Row>[
    if (_hasArrived)
      _Row(
        id: 'n0',
        module: NotificationModule.studentAttendance,
        action: NotificationAction.studentSignInOut,
        subject: 'Ivy Chen',
        title: 'Ivy Chen signed in',
        body: 'Signed in by Wei Chen at the door kiosk.',
        at: _at(20, 9, 41),
        targetCode: 'ivy',
        classroom: 'Sunflower',
      ),

    // --- Today ---------------------------------------------------------
    _Row(
      id: 'n1',
      module: NotificationModule.activity,
      action: NotificationAction.incidentApprovalPending,
      subject: 'Aisha Bello',
      title: 'Incident awaiting your approval',
      body: 'Aisha Bello recorded a bumped knee in Sunflower at 9:04 AM.',
      at: _at(20, 9, 37),
      classroom: 'Sunflower',
    ),
    _Row(
      id: 'n2',
      module: NotificationModule.attendance,
      action: NotificationAction.ratioBreached,
      subject: 'Bluebell',
      title: 'Bluebell is not in ratio',
      body:
          '7 students are signed in with 1 staff member. One more staff '
          'member must be in the classroom.',
      at: _at(20, 9, 29),
      targetCode: 'bluebell',
      classroom: 'Bluebell',
    ),
    _Row(
      id: 'n3',
      module: NotificationModule.studentAttendance,
      action: NotificationAction.studentSignInOut,
      subject: 'Sam Okafor',
      title: 'Sam Okafor signed out',
      body: 'Collected by Ngozi Okafor at 9:20 AM.',
      at: _at(20, 9, 20),
      targetCode: 'sam',
      classroom: 'Sunflower',
      studentId: 'sam',
    ),
    _Row(
      id: 'n4',
      module: NotificationModule.studentAttendance,
      action: NotificationAction.studentSignInOut,
      subject: 'Amara Okafor',
      title: 'Amara Okafor signed in',
      body: 'Signed in by Ngozi Okafor at the door kiosk.',
      at: _at(20, 9, 12),
      targetCode: 'amara',
      classroom: 'Sunflower',
      studentId: 'amara',
    ),
    _Row(
      id: 'n5',
      module: NotificationModule.staffAttendance,
      action: NotificationAction.staffSignInOut,
      subject: 'Tomas Berg',
      title: 'Tomas Berg signed out',
      body: 'Bluebell · signed out at 9:05 AM.',
      at: _at(20, 9, 5),
      targetCode: 'tomas',
      classroom: 'Bluebell',
    ),
    _Row(
      id: 'n6',
      module: NotificationModule.billing,
      action: NotificationAction.invoiceGenerated,
      subject: 'Okafor Family',
      title: 'Invoice INV-2419 was sent',
      body: r'$420.00 to the Okafor family, due 27 August.',
      at: _at(20, 8, 41),
      isFamily: true,
    ),
    _Row(
      id: 'n7',
      module: NotificationModule.activity,
      action: NotificationAction.activityRecorded,
      subject: 'Dana Whitfield',
      title: 'Breakfast was recorded for Sunflower',
      body: 'Dana Whitfield logged breakfast for 11 students.',
      at: _at(20, 8, 32),
      classroom: 'Sunflower',
    ),
    _Row(
      id: 'n8',
      module: NotificationModule.scheduling,
      action: NotificationAction.publishShift,
      subject: 'Dana Whitfield',
      title: "Dana Whitfield's shift was published",
      body: 'Sunflower · Friday 21 August, 13:00 to 18:00.',
      at: _at(20, 8, 10),
      targetCode: 'dana',
      classroom: 'Sunflower',
      isRead: true,
    ),
    _Row(
      id: 'n9',
      module: NotificationModule.availability,
      action: NotificationAction.movementOverdue,
      subject: 'Ada Kowalski',
      title: 'Movement overdue',
      body: 'Ada Kowalski was due to move Bluebell to Sunflower on 18 August.',
      at: _at(20, 7, 55),
      targetCode: 'ada',
      classroom: 'Sunflower',
      isRead: true,
    ),
    _Row(
      id: 'n10',
      module: NotificationModule.messaging,
      action: NotificationAction.messageToStudent,
      subject: 'Ngozi Okafor',
      title: 'New message in Sunflower Room Chat',
      body: "Ngozi Okafor: 'Amara will be picked up at 4 today.'",
      at: _at(20, 7, 38),
      classroom: 'Sunflower',
      studentId: 'amara',
      isRead: true,
    ),
    _Row(
      id: 'n11',
      module: NotificationModule.activity,
      action: NotificationAction.activityRecorded,
      subject: 'Amara Okafor',
      title: 'Amara Okafor had breakfast',
      body: 'Dana Whitfield recorded breakfast at 8:40 AM.',
      at: _at(20, 8, 55),
      targetCode: 'amara',
      classroom: 'Sunflower',
      studentId: 'amara',
      isRead: true,
    ),

    // --- Yesterday -----------------------------------------------------
    _Row(
      id: 'n12',
      module: NotificationModule.student,
      action: NotificationAction.studentImmunizationDueOverdue,
      subject: 'Maya Ibrahim',
      title: 'Immunization record due',
      body: 'Maya Ibrahim · the DTaP booster was due 15 August.',
      at: _at(19, 16, 15),
      targetCode: 'maya',
      classroom: 'Bluebell',
      isRead: true,
    ),
    _Row(
      id: 'n13',
      module: NotificationModule.staff,
      action: NotificationAction.staffDocumentExpiry,
      subject: 'Priya Raman',
      title: 'Priya Raman has a document expiring',
      body: 'The CPR certificate on file expires 12 September.',
      at: _at(19, 15, 40),
      targetCode: 'priya',
      classroom: 'Bluebell',
      isRead: true,
    ),
    _Row(
      id: 'n14',
      module: NotificationModule.attendance,
      action: NotificationAction.attendanceNotMarked,
      subject: 'Acorn',
      title: 'Acorn attendance was not taken',
      body: '9 students were still Not Marked at 2:00 PM.',
      at: _at(19, 14, 5),
      classroom: 'Acorn',
      isRead: true,
    ),
    _Row(
      id: 'n15',
      module: NotificationModule.activity,
      action: NotificationAction.activityRecorded,
      subject: 'Ruth Adeyinka',
      title: 'Lunch was recorded for Acorn',
      body: 'Ruth Adeyinka logged lunch for 9 students.',
      at: _at(19, 13, 20),
      classroom: 'Acorn',
      isRead: true,
    ),
    _Row(
      id: 'n16',
      module: NotificationModule.newsletter,
      action: NotificationAction.newsletterSent,
      subject: DemoData.schoolName,
      title: 'August newsletter was sent',
      body: 'Sent to 74 families across three classrooms.',
      at: _at(19, 11, 2),
      isSchoolWide: true,
      isRead: true,
    ),
    _Row(
      id: 'n17',
      module: NotificationModule.billing,
      action: NotificationAction.paymentSuccess,
      subject: 'Duarte Family',
      title: 'Payment received',
      body: r'$310.00 from the Duarte family against INV-2404.',
      at: _at(19, 10, 15),
      isRead: true,
    ),
    _Row(
      id: 'n18',
      module: NotificationModule.classroom,
      action: NotificationAction.editClassroom,
      subject: 'Sunflower',
      title: 'Sunflower was edited',
      body: 'Capacity changed from 12 to 14 places by Marcus Whitfield.',
      at: _at(19, 9, 12),
      targetCode: 'sunflower',
      classroom: 'Sunflower',
      isRead: true,
    ),
    _Row(
      id: 'n19',
      module: NotificationModule.scheduling,
      action: NotificationAction.editShift,
      subject: 'Hugo Marsh',
      title: "Hugo Marsh's shift changed",
      body: 'Acorn · Thursday 20 August, 09:00 to 15:00.',
      at: _at(19, 8, 20),
      targetCode: 'hugo',
      classroom: 'Acorn',
      isRead: true,
    ),
    _Row(
      id: 'n20',
      module: NotificationModule.studentAttendance,
      action: NotificationAction.studentMarkedAbsent,
      subject: 'Lila Suarez',
      title: 'Lila Suarez was marked absent',
      body: 'Marked absent by Elena Suarez at 7:55 AM.',
      at: _at(19, 7, 55),
      targetCode: 'lila',
      classroom: 'Sunflower',
      isRead: true,
    ),
    _Row(
      id: 'n21',
      module: NotificationModule.messaging,
      action: NotificationAction.messageToStaff,
      subject: 'Grace Park',
      title: 'New message from Grace Park',
      body: "Grace Park: 'Jonah has a late pickup on Friday.'",
      at: _at(19, 7, 20),
      classroom: 'Sunflower',
      isRead: true,
    ),

    // --- Earlier -------------------------------------------------------
    _Row(
      id: 'n22',
      module: NotificationModule.availability,
      action: NotificationAction.upcomingMovement,
      subject: 'Sena Adjei',
      title: 'Movement coming up',
      body: 'Sena Adjei moves Bluebell to Sunflower on 1 September.',
      at: _at(18, 16, 40),
      targetCode: 'sena',
      classroom: 'Bluebell',
      isRead: true,
    ),
    _Row(
      id: 'n23',
      module: NotificationModule.student,
      action: NotificationAction.studentPhysicalOverdue,
      subject: 'Otto Lindqvist',
      title: 'Physical exam overdue',
      body: 'Otto Lindqvist · the annual physical was due 10 August.',
      at: _at(18, 12, 5),
      targetCode: 'otto',
      classroom: 'Bluebell',
      isRead: true,
    ),
    _Row(
      id: 'n24',
      module: NotificationModule.staffAttendance,
      action: NotificationAction.staffMarkedAbsent,
      subject: 'Aisha Bello',
      title: 'Aisha Bello was marked absent',
      body: 'Marked absent at 6:58 AM.',
      at: _at(18, 9, 30),
      targetCode: 'aisha',
      classroom: 'Sunflower',
      isRead: true,
    ),
    _Row(
      id: 'n25',
      module: NotificationModule.billing,
      action: NotificationAction.invoiceDue,
      subject: 'Adeyemi Family',
      title: 'Invoice INV-2402 is due tomorrow',
      body: r'$395.00 to the Adeyemi family, due 19 August.',
      at: _at(18, 8, 15),
      isRead: true,
    ),
    _Row(
      id: 'n26',
      module: NotificationModule.classroom,
      action: NotificationAction.assignStudentToClassroom,
      subject: 'Bluebell',
      title: 'Rumi Tanaka joined Bluebell',
      body: 'Assigned by Marcus Whitfield on 18 August.',
      at: _at(18, 7, 45),
      targetCode: 'bluebell',
      classroom: 'Bluebell',
      isRead: true,
    ),
  ];

  /// The design draws every frame on 20 August 2026.
  static DateTime _at(int day, int hour, int minute) =>
      DateTime(DemoData.today.year, DemoData.today.month, day, hour, minute);
}

/// A fixture row: a notification, plus the two facts the server would have
/// scoped it by before it ever reached a phone.
class _Row {
  const _Row({
    required this.id,
    required this.module,
    required this.action,
    required this.subject,
    required this.title,
    required this.body,
    required this.at,
    this.targetCode,
    this.classroom,
    this.studentId,
    this.isFamily = false,
    this.isSchoolWide = false,
    this.isRead = false,
  });

  final String id;
  final NotificationModule module;
  final String action;
  final String subject;
  final String title;
  final String body;
  final DateTime at;
  final String? targetCode;

  /// The classroom this is about. A staff member is only told about their
  /// own.
  final String? classroom;

  /// The student this is about, when it is about one. A guardian is only told
  /// about their own children.
  final String? studentId;

  /// Money about the guardian's own family.
  final bool isFamily;

  /// Something everybody at the school is told, a newsletter being the one
  /// that matters here.
  final bool isSchoolWide;

  final bool isRead;

  NotificationItem item({required bool read}) => NotificationItem(
    id: id,
    title: title,
    body: body,
    subjectName: subject,
    module: module,
    action: action,
    targetCode: targetCode,
    createdAt: at,
    isRead: read,
  );

  /// 12e, as the server would apply it.
  bool reaches(Persona persona) => switch (persona) {
    // The whole school.
    Persona.admin => true,

    // Their classroom, their own record, and never money.
    Persona.staff =>
      module != NotificationModule.billing &&
          (isSchoolWide ||
              classroom == PreviewNotificationsSource._staffClassroom),

    // Their children, their money, and what was written to them.
    Persona.guardian =>
      isSchoolWide ||
          isFamily ||
          (studentId != null &&
              PreviewNotificationsSource._guardianChildren.contains(studentId)),
  };
}
