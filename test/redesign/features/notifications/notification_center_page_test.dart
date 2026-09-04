import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/session/badge_cubit.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';
import 'package:wowcare/redesign/features/notifications/presentation/pages/notification_center_page.dart';
import 'package:wowcare/redesign/features/notifications/presentation/widgets/notification_row.dart';
import 'package:wowcare/redesign/features/notifications/presentation/widgets/notification_skeleton.dart';

import 'harness.dart';

void main() {
  final source = FakeNotificationsSource();
  useSource(source);

  setUp(() {
    source
      ..items = List<NotificationItem>.of(sampleFeed)
      ..throwsOnRead = false
      ..throwsOnWrite = false
      ..readDelay = Duration.zero
      ..didMarkAll = false
      ..readId = null;
  });

  tearDownAll(source.dispose);

  group('12a: the center', () {
    testWidgets('draws the title, the unread line and the first page', (
      tester,
    ) async {
      await pumpScreen(tester, const NotificationCenterPage());

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('6 unread'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Incident awaiting your approval'), findsOneWidget);
      expect(find.text('Activity'), findsWidgets);
      expect(find.text('4 mins ago'), findsOneWidget);
      expect(find.byType(NotificationRow), findsWidgets);
    });

    testWidgets('draws the one action and the unread switch', (tester) async {
      await pumpScreen(tester, const NotificationCenterPage());

      expect(find.text('Mark all as read'), findsOneWidget);
      expect(find.text('Only Show Unread'), findsOneWidget);
    });

    testWidgets('12e: an admin is offered every chip', (tester) async {
      await pumpScreen(tester, const NotificationCenterPage());

      expect(find.widgetWithText(AppChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(AppChip, 'Billing'), findsOneWidget);
      expect(find.widgetWithText(AppChip, 'Staff'), findsOneWidget);
      expect(find.widgetWithText(AppChip, 'Scheduling'), findsOneWidget);
    });

    testWidgets('12e: a guardian is offered only what is theirs', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const NotificationCenterPage(),
        persona: Persona.guardian,
      );

      expect(find.widgetWithText(AppChip, 'Billing'), findsOneWidget);
      expect(find.widgetWithText(AppChip, 'Staff'), findsNothing);
      expect(find.widgetWithText(AppChip, 'Scheduling'), findsNothing);
      expect(find.widgetWithText(AppChip, 'Classroom'), findsNothing);
    });

    testWidgets('12d: the bell is given the unread total', (tester) async {
      final badges = BadgeCubit();
      addTearDown(badges.close);

      await pumpScreen(tester, const NotificationCenterPage(), badges: badges);

      expect(badges.state.notifications, 6);
    });

    testWidgets('12d: mark all reads everything and empties the bell', (
      tester,
    ) async {
      final badges = BadgeCubit();
      addTearDown(badges.close);

      await pumpScreen(tester, const NotificationCenterPage(), badges: badges);
      await tester.tap(find.text('Mark all as read'));
      await settle(tester);

      expect(source.didMarkAll, isTrue);
      expect(find.text('All read'), findsOneWidget);
      expect(badges.state.notifications, 0);
      await settleToast(tester);
    });

    testWidgets('12d: reading one row drops the bell by one', (tester) async {
      final badges = BadgeCubit();
      addTearDown(badges.close);

      await pumpScreen(tester, const NotificationCenterPage(), badges: badges);
      await tester.tap(find.text('Invoice INV-2419 was sent'));
      await settle(tester);

      expect(source.readId, 'a4');
      expect(find.text('5 unread'), findsOneWidget);
      expect(badges.state.notifications, 5);
      await settleToast(tester);
    });

    testWidgets('12c: a module that is not rebuilt yet says so', (
      tester,
    ) async {
      await pumpScreen(tester, const NotificationCenterPage());
      await tester.tap(find.text('Invoice INV-2419 was sent'));
      await settle(tester);

      expect(find.text(AppStrings.comingSoon), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('12a: reaching the end fetches the next ten, and says so', (
      tester,
    ) async {
      source.readDelay = const Duration(milliseconds: 200);
      await pumpScreen(tester, const NotificationCenterPage());
      expect(find.text('Loading more'), findsNothing);

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).last)
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();

      expect(find.text('Loading more'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      expect(source.lastPage, 1);
      expect(find.text('Loading more'), findsNothing);
      expect(find.text('YESTERDAY'), findsOneWidget);
    });

    testWidgets('a chip refetches under that filter', (tester) async {
      await pumpScreen(tester, const NotificationCenterPage());
      await tapChip(tester, 'Billing');

      expect(source.lastFilter, NotificationFilter.billing);
      expect(find.text('Invoice INV-2419 was sent'), findsOneWidget);
      expect(find.text('Incident awaiting your approval'), findsNothing);
    });
  });

  group('12b: the states', () {
    testWidgets('the first load keeps the page height', (tester) async {
      source.readDelay = const Duration(milliseconds: 300);
      await tester.pumpWidget(host(const NotificationCenterPage()));
      await tester.pump();

      expect(find.byType(NotificationSkeleton), findsOneWidget);
      expect(find.text('Loading your notifications…'), findsOneWidget);
      // The toolbar waits until there is something to act on.
      expect(find.text('Mark all as read'), findsNothing);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(NotificationSkeleton), findsNothing);
    });

    testWidgets('an inbox with nothing in it is caught up, not broken', (
      tester,
    ) async {
      source.items = const <NotificationItem>[];
      await pumpScreen(tester, const NotificationCenterPage());

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('No notifications to show'), findsOneWidget);
      expect(find.text('All read'), findsOneWidget);
    });

    testWidgets('a filter that matches nothing says which', (tester) async {
      source.items = List<NotificationItem>.of(
        sampleFeed.where((i) => i.module != NotificationModule.billing),
      );
      await pumpScreen(tester, const NotificationCenterPage());
      await tapChip(tester, 'Billing');

      expect(find.text('Nothing under that filter'), findsOneWidget);
      expect(find.text('Tap All to see everything again'), findsOneWidget);
    });

    testWidgets('a failed load with nothing to fall back on offers a retry', (
      tester,
    ) async {
      source.throwsOnRead = true;
      await pumpScreen(tester, const NotificationCenterPage());

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text("Couldn't load notifications"), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);

      source.throwsOnRead = false;
      await tester.tap(find.text(AppStrings.retry));
      await settle(tester);

      expect(find.byType(ErrorState), findsNothing);
      expect(find.text('Incident awaiting your approval'), findsOneWidget);
    });

    testWidgets('a push arriving reloads the list and says so', (tester) async {
      await pumpScreen(tester, const NotificationCenterPage());
      source.pushArrival();
      await settle(tester);

      expect(find.text('One arrived while you were reading'), findsOneWidget);
      expect(find.text('Incident awaiting your approval'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the list and raises the banner', (
      tester,
    ) async {
      await pumpScreen(tester, const NotificationCenterPage());
      source.throwsOnRead = true;

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.offlineBanner), findsOneWidget);
      expect(find.text('Incident awaiting your approval'), findsOneWidget);
    });
  });
}
