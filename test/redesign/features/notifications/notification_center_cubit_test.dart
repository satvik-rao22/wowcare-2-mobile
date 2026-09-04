import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/notifications/cubit/notification_center_cubit.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';

import 'harness.dart';

void main() {
  late FakeNotificationsSource source;

  NotificationCenterCubit build({Persona persona = Persona.admin}) =>
      NotificationCenterCubit(source: source, persona: persona);

  setUp(() => source = FakeNotificationsSource());
  tearDown(() => source.dispose());

  group('NotificationCenterCubit', () {
    test('12a: the first page is ten rows, with more behind it', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, NotificationCenterStatus.ready);
      expect(cubit.state.items.length, NotificationCenterCubit.pageSize);
      expect(cubit.state.hasMore, isTrue);
      // The total spans every page, not just the rows loaded.
      expect(cubit.state.unreadCount, 6);
      expect(cubit.state.hasUnread, isTrue);
      await cubit.close();
    });

    test('12a: the rows arrive banded by day', () async {
      final cubit = build();
      await cubit.load();

      final groups = cubit.state.groups;
      expect(groups.first.day, NotificationDay.today);
      expect(groups.first.items.length, NotificationCenterCubit.pageSize);
      expect(groups.length, 1);

      await cubit.loadMore();
      final banded = cubit.state.groups;
      expect(banded.length, 2);
      expect(banded.last.day, NotificationDay.yesterday);
      expect(banded.last.items.length, 2);
      await cubit.close();
    });

    test('12b: an inbox with nothing in it is ready, not failed', () async {
      source.items = const <NotificationItem>[];
      final cubit = build();
      await cubit.load();

      expect(cubit.state.status, NotificationCenterStatus.ready);
      expect(cubit.state.isEmpty, isTrue);
      expect(cubit.state.isNarrowed, isFalse);
      await cubit.close();
    });

    test('12b: a failed fetch with nothing on screen fails outright', () async {
      source.throwsOnRead = true;
      final cubit = build();
      await cubit.load();

      expect(cubit.state.isFailed, isTrue);
      expect(cubit.state.isEmpty, isTrue);
      await cubit.close();
    });

    test(
      'a failed refetch with rows on screen is cached, not failed',
      () async {
        final cubit = build();
        await cubit.load();
        source.throwsOnRead = true;
        await cubit.refresh();

        expect(cubit.state.isCached, isTrue);
        expect(cubit.state.items, isNotEmpty);
        await cubit.close();
      },
    );

    test('the next page is appended, and then there is no more', () async {
      final cubit = build();
      await cubit.load();
      await cubit.loadMore();

      expect(cubit.state.items.length, 12);
      expect(cubit.state.page, 1);
      expect(cubit.state.hasMore, isFalse);
      expect(source.lastPage, 1);

      // Nothing left to ask for.
      final calls = source.pageCalls;
      await cubit.loadMore();
      expect(source.pageCalls, calls);
      await cubit.close();
    });

    test('a page that overlaps the last one is de-duped', () async {
      final cubit = build();
      await cubit.load();
      // Every page answers with the same first ten.
      source.items = List<NotificationItem>.of(sampleFeed.take(10));
      await cubit.loadMore();

      expect(cubit.state.items.length, 10);
      await cubit.close();
    });

    test('a chip refetches from page one with that filter', () async {
      final cubit = build();
      await cubit.load();
      await cubit.setFilter(NotificationFilter.billing);

      expect(source.lastFilter, NotificationFilter.billing);
      expect(source.lastPage, 0);
      expect(cubit.state.items.single.module, NotificationModule.billing);
      expect(cubit.state.isNarrowed, isTrue);

      // The same chip again asks for nothing.
      final calls = source.pageCalls;
      await cubit.setFilter(NotificationFilter.billing);
      expect(source.pageCalls, calls);
      await cubit.close();
    });

    test('only-unread is a server filter, not a hidden row', () async {
      final cubit = build();
      await cubit.load();
      await cubit.setOnlyUnread(value: true);

      expect(source.lastOnlyUnread, isTrue);
      expect(cubit.state.items.length, 6);
      expect(cubit.state.items.every((i) => !i.isRead), isTrue);
      await cubit.close();
    });

    test('12b: an empty answer under a filter is a narrowed empty', () async {
      source.items = List<NotificationItem>.of(
        sampleFeed.where((i) => i.module != NotificationModule.billing),
      );
      final cubit = build();
      await cubit.load();
      await cubit.setFilter(NotificationFilter.billing);

      expect(cubit.state.isEmpty, isTrue);
      expect(cubit.state.isNarrowed, isTrue);
      expect(cubit.state.isFailed, isFalse);
      await cubit.close();
    });

    test('12d: reading one row drops the count by one', () async {
      final cubit = build();
      await cubit.load();
      await cubit.markRead('a1');

      expect(cubit.state.items.first.isRead, isTrue);
      expect(cubit.state.unreadCount, 5);
      expect(source.readId, 'a1');

      // Reading it again asks for nothing.
      source.readId = null;
      await cubit.markRead('a1');
      expect(source.readId, isNull);
      await cubit.close();
    });

    test('a read that fails puts the dot back', () async {
      final cubit = build();
      await cubit.load();
      source.throwsOnWrite = true;
      await cubit.markRead('a1');

      expect(cubit.state.items.first.isRead, isFalse);
      expect(cubit.state.unreadCount, 6);
      await cubit.close();
    });

    test('12d: mark all takes the count to nothing at once', () async {
      final cubit = build();
      await cubit.load();
      final didMark = await cubit.markAllRead();

      expect(didMark, isTrue);
      expect(cubit.state.unreadCount, 0);
      expect(cubit.state.hasUnread, isFalse);
      expect(cubit.state.items.every((i) => i.isRead), isTrue);
      expect(source.didMarkAll, isTrue);

      // With nothing unread it is a no-op.
      expect(await cubit.markAllRead(), isFalse);
      await cubit.close();
    });

    test('a mark all that fails rolls the whole list back', () async {
      final cubit = build();
      await cubit.load();
      source.throwsOnWrite = true;

      expect(await cubit.markAllRead(), isFalse);
      expect(cubit.state.unreadCount, 6);
      expect(cubit.state.items.first.isRead, isFalse);
      await cubit.close();
    });

    test('12b: a push arriving reloads the list and says so', () async {
      final cubit = build();
      await cubit.load();
      final calls = source.pageCalls;

      source.pushArrival();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.hasArrived, isTrue);
      expect(source.pageCalls, greaterThan(calls));

      cubit.dismissArrival();
      expect(cubit.state.hasArrived, isFalse);
      await cubit.close();
    });

    test('12e: the chips offered follow the persona', () async {
      final admin = build();
      final staff = build(persona: Persona.staff);
      final guardian = build(persona: Persona.guardian);

      expect(admin.state.chips, NotificationFilter.values);
      expect(staff.state.chips, isNot(contains(NotificationFilter.billing)));
      expect(guardian.state.chips, contains(NotificationFilter.billing));
      expect(
        guardian.state.chips,
        isNot(contains(NotificationFilter.scheduling)),
      );
      expect(guardian.state.chips, isNot(contains(NotificationFilter.staff)));

      await admin.close();
      await staff.close();
      await guardian.close();
    });

    test('the persona is what the feed is fetched for', () async {
      final cubit = build(persona: Persona.guardian);
      await cubit.load();

      expect(source.lastPersona, Persona.guardian);
      await cubit.close();
    });
  });
}
