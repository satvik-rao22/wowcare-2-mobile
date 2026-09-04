import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_action.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/preview/preview_session_source.dart';
import 'package:wowcare/redesign/core/session/badge_cubit.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';
import 'package:wowcare/redesign/features/notifications/notifications_di.dart';
import 'package:wowcare/redesign/features/notifications/source/notifications_source.dart';

/// What M12's screen is pumped in, and the source its states are driven by.

/// The phone the frames are drawn at.
const Size phone = Size(390, 844);

/// Wraps [child] in the theme, the session and the badge every M12 screen
/// reads.
Widget host(
  Widget child, {
  Persona persona = Persona.admin,
  BadgeCubit? badges,
}) {
  final user = switch (persona) {
    Persona.admin => DemoData.admin,
    Persona.staff => DemoData.staff,
    Persona.guardian => DemoData.guardian,
  };
  final session = SessionCubit(source: const PreviewSessionSource())
    ..signedIn(user)
    ..switchPersona(persona);

  return MaterialApp(
    theme: AppTheme.light,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<SessionCubit>.value(value: session),
        BlocProvider<BadgeCubit>.value(value: badges ?? BadgeCubit()),
      ],
      child: child,
    ),
  );
}

/// Pumps a screen on a phone-sized surface and lets its first load land.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  Persona persona = Persona.admin,
  BadgeCubit? badges,
}) async {
  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(host(child, persona: persona, badges: badges));
  await settle(tester);
}

/// Drains the microtasks a fetch resolves on, then the frames that follow.
/// `pumpAndSettle` alone is no good while a loading ring is spinning.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 500));
}

/// Lets a toast live out its five seconds, so no timer outlives the test.
Future<void> settleToast(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 6));

/// Scrolls a filter chip into the row and taps it. The chip row runs past
/// both gutters, so most of the chips start off screen.
Future<void> tapChip(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(AppChip, label);
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await settle(tester);
}

/// Registers M12 on the redesign's own locator with [source] behind it, and
/// tears the registrations down again after the test.
void useSource(NotificationsSource source) {
  setUp(() {
    registerNotificationsDependencies(redesignLocator);
    redesignLocator
      ..unregister<NotificationsSource>()
      ..registerSingleton<NotificationsSource>(source);
  });
  tearDown(redesignLocator.reset);
}

/// A source the tests drive by hand.
///
/// A fake rather than a mock: the inbox is paged, filtered and marked read
/// against the same list, so setting the world up says more about the
/// behaviour than stubbing each call would.
class FakeNotificationsSource implements NotificationsSource {
  FakeNotificationsSource({List<NotificationItem>? items})
    : items = items ?? List<NotificationItem>.of(sampleFeed);

  List<NotificationItem> items;

  /// Set, every read throws.
  bool throwsOnRead = false;

  /// How long a read takes. Zero unless a test wants to see the state the
  /// screen is in before the answer arrives.
  Duration readDelay = Duration.zero;

  /// Set, every write throws.
  bool throwsOnWrite = false;

  int pageCalls = 0;
  int? lastPage;
  NotificationFilter? lastFilter;
  bool? lastOnlyUnread;
  Persona? lastPersona;
  String? readId;
  bool didMarkAll = false;

  final StreamController<void> _arrivals = StreamController<void>.broadcast();

  @override
  Stream<void> get arrivals => _arrivals.stream;

  /// A push landing while the center is open.
  void pushArrival() => _arrivals.add(null);

  void dispose() => unawaited(_arrivals.close());

  @override
  Future<NotificationFeed> loadPage({
    required Persona persona,
    required int page,
    required int pageSize,
    NotificationFilter filter = NotificationFilter.all,
    bool onlyUnread = false,
  }) async {
    pageCalls += 1;
    lastPage = page;
    lastFilter = filter;
    lastOnlyUnread = onlyUnread;
    lastPersona = persona;
    if (readDelay > Duration.zero) await Future<void>.delayed(readDelay);
    if (throwsOnRead) throw const NotificationsUnavailable();

    final matching = <NotificationItem>[
      for (final item in items)
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
      unreadCount: items.where((i) => !i.isRead).length,
    );
  }

  @override
  Future<void> markRead(String id) async {
    if (throwsOnWrite) throw const NotificationsUnavailable();
    readId = id;
    items = <NotificationItem>[
      for (final item in items)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
  }

  @override
  Future<void> markAllRead() async {
    if (throwsOnWrite) throw const NotificationsUnavailable();
    didMarkAll = true;
    items = <NotificationItem>[
      for (final item in items) item.copyWith(isRead: true),
    ];
  }
}

/// Twelve rows on the design's own day: ten today and two the day before, so
/// one page fills and the second one is short.
final List<NotificationItem> sampleFeed = <NotificationItem>[
  _item(
    id: 'a1',
    title: 'Incident awaiting your approval',
    body: 'Aisha Bello recorded a bumped knee in Sunflower at 9:04 AM.',
    subject: 'Aisha Bello',
    module: NotificationModule.activity,
    action: NotificationAction.incidentApprovalPending,
    hour: 9,
    minute: 37,
  ),
  _item(
    id: 'a2',
    title: 'Bluebell is not in ratio',
    body: '7 students are signed in with 1 staff member.',
    subject: 'Bluebell',
    module: NotificationModule.attendance,
    action: NotificationAction.ratioBreached,
    targetCode: 'bluebell',
    hour: 9,
    minute: 29,
  ),
  _item(
    id: 'a3',
    title: 'Amara Okafor signed in',
    body: 'Signed in by Ngozi Okafor at the door kiosk.',
    subject: 'Amara Okafor',
    module: NotificationModule.studentAttendance,
    action: NotificationAction.studentSignInOut,
    targetCode: 'amara',
    hour: 9,
    minute: 12,
  ),
  _item(
    id: 'a4',
    title: 'Invoice INV-2419 was sent',
    body: r'$420.00 to the Okafor family, due 27 August.',
    subject: 'Okafor Family',
    module: NotificationModule.billing,
    action: NotificationAction.invoiceGenerated,
    hour: 8,
    minute: 41,
  ),
  _item(
    id: 'a5',
    title: 'Breakfast was recorded for Sunflower',
    body: 'Dana Whitfield logged breakfast for 11 students.',
    subject: 'Dana Whitfield',
    module: NotificationModule.activity,
    action: NotificationAction.activityRecorded,
    hour: 8,
    minute: 32,
  ),
  _item(
    id: 'a6',
    title: 'Tomas Berg signed out',
    body: 'Bluebell · signed out at 8:20 AM.',
    subject: 'Tomas Berg',
    module: NotificationModule.staffAttendance,
    action: NotificationAction.staffSignInOut,
    targetCode: 'tomas',
    hour: 8,
    minute: 20,
  ),
  _item(
    id: 'a7',
    title: "Dana Whitfield's shift was published",
    body: 'Sunflower · Friday 21 August, 13:00 to 18:00.',
    subject: 'Dana Whitfield',
    module: NotificationModule.scheduling,
    action: NotificationAction.publishShift,
    targetCode: 'dana',
    hour: 8,
    minute: 10,
    isRead: true,
  ),
  _item(
    id: 'a8',
    title: 'Movement overdue',
    body: 'Ada Kowalski was due to move Bluebell to Sunflower.',
    subject: 'Ada Kowalski',
    module: NotificationModule.availability,
    action: NotificationAction.movementOverdue,
    targetCode: 'ada',
    hour: 7,
    minute: 55,
    isRead: true,
  ),
  _item(
    id: 'a9',
    title: 'New message in Sunflower Room Chat',
    body: "Ngozi Okafor: 'Amara will be picked up at 4 today.'",
    subject: 'Ngozi Okafor',
    module: NotificationModule.messaging,
    action: NotificationAction.messageToStudent,
    hour: 7,
    minute: 38,
    isRead: true,
  ),
  _item(
    id: 'a10',
    title: 'Sunflower was edited',
    body: 'Capacity changed from 12 to 14 places by Marcus Whitfield.',
    subject: 'Sunflower',
    module: NotificationModule.classroom,
    action: NotificationAction.editClassroom,
    targetCode: 'sunflower',
    hour: 7,
    minute: 20,
    isRead: true,
  ),
  _item(
    id: 'a11',
    title: 'Immunization record due',
    body: 'Maya Ibrahim · the DTaP booster was due 15 August.',
    subject: 'Maya Ibrahim',
    module: NotificationModule.student,
    action: NotificationAction.studentImmunizationDueOverdue,
    targetCode: 'maya',
    day: 19,
    hour: 16,
    minute: 15,
    isRead: true,
  ),
  _item(
    id: 'a12',
    title: 'August newsletter was sent',
    body: 'Sent to 74 families across three classrooms.',
    subject: DemoData.schoolName,
    module: NotificationModule.newsletter,
    action: NotificationAction.newsletterSent,
    day: 19,
    hour: 11,
    minute: 2,
    isRead: true,
  ),
];

NotificationItem _item({
  required String id,
  required String title,
  required String body,
  required String subject,
  required NotificationModule module,
  required String action,
  required int hour,
  required int minute,
  String? targetCode,
  int day = 20,
  bool isRead = false,
}) => NotificationItem(
  id: id,
  title: title,
  body: body,
  subjectName: subject,
  module: module,
  action: action,
  targetCode: targetCode,
  createdAt: DateTime(2026, 8, day, hour, minute),
  isRead: isRead,
);
