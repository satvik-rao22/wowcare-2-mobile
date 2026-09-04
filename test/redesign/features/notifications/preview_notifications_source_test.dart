import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/notifications/models/models.dart';
import 'package:wowcare/redesign/features/notifications/source/notifications_source.dart';
import 'package:wowcare/redesign/features/notifications/source/preview_notifications_source.dart';

void main() {
  const pageSize = 10;

  Future<List<NotificationItem>> everything(
    PreviewNotificationsSource source, {
    required Persona persona,
  }) async {
    final all = <NotificationItem>[];
    var page = 0;
    var more = true;
    while (more) {
      final feed = await source.loadPage(
        persona: persona,
        page: page,
        pageSize: pageSize,
      );
      all.addAll(feed.items);
      more = feed.hasMore;
      page += 1;
    }
    return all;
  }

  group('PreviewNotificationsSource', () {
    test('12a: the first page is ten, and there is more behind it', () async {
      final source = PreviewNotificationsSource();
      addTearDown(source.dispose);

      final feed = await source.loadPage(
        persona: Persona.admin,
        page: 0,
        pageSize: pageSize,
      );

      expect(feed.items.length, pageSize);
      expect(feed.hasMore, isTrue);
      // The count the app's own bell fixture carries.
      expect(feed.unreadCount, 7);
      expect(feed.items.first.title, 'Incident awaiting your approval');
    });

    test('the pages run out, and every row is distinct', () async {
      final source = PreviewNotificationsSource();
      addTearDown(source.dispose);

      final all = await everything(source, persona: Persona.admin);

      expect(all.length, 26);
      expect(all.map((i) => i.id).toSet().length, all.length);
      // Newest first.
      expect(all.first.createdAt.isAfter(all.last.createdAt), isTrue);
    });

    test('12e: a staff member is never told about money', () async {
      final source = PreviewNotificationsSource();
      addTearDown(source.dispose);

      final all = await everything(source, persona: Persona.staff);

      expect(all, isNotEmpty);
      expect(all.any((i) => i.module == NotificationModule.billing), isFalse);
    });

    test('12e: a guardian is told about their children and their own '
        'money', () async {
      final source = PreviewNotificationsSource();
      addTearDown(source.dispose);

      final all = await everything(source, persona: Persona.guardian);

      expect(all, isNotEmpty);
      expect(
        all.any((i) => i.module == NotificationModule.staffAttendance),
        isFalse,
      );
      expect(
        all.any((i) => i.module == NotificationModule.scheduling),
        isFalse,
      );
      expect(all.any((i) => i.title.contains('Amara Okafor')), isTrue);
      expect(all.any((i) => i.module == NotificationModule.billing), isTrue);
    });

    test('a filter is applied before the page is cut', () async {
      final source = PreviewNotificationsSource();
      addTearDown(source.dispose);

      final feed = await source.loadPage(
        persona: Persona.admin,
        page: 0,
        pageSize: pageSize,
        filter: NotificationFilter.billing,
      );

      expect(feed.items, isNotEmpty);
      expect(
        feed.items.every((i) => i.module == NotificationModule.billing),
        isTrue,
      );
      expect(feed.hasMore, isFalse);
      // The unread total still spans the whole inbox.
      expect(feed.unreadCount, 7);
    });

    test('reading a row survives the next fetch', () async {
      final source = PreviewNotificationsSource();
      addTearDown(source.dispose);

      await source.markRead('n1');
      final feed = await source.loadPage(
        persona: Persona.admin,
        page: 0,
        pageSize: pageSize,
      );

      expect(feed.items.first.isRead, isTrue);
      expect(feed.unreadCount, 6);

      await source.markAllRead();
      final marked = await source.loadPage(
        persona: Persona.admin,
        page: 0,
        pageSize: pageSize,
      );
      expect(marked.unreadCount, 0);
    });

    test('the empty mode is an account nothing has arrived for', () async {
      final source = PreviewNotificationsSource(
        mode: PreviewNotificationsMode.empty,
      );
      addTearDown(source.dispose);

      final feed = await source.loadPage(
        persona: Persona.admin,
        page: 0,
        pageSize: pageSize,
      );

      expect(feed.items, isEmpty);
      expect(feed.hasMore, isFalse);
    });

    test('the failed mode throws every time', () async {
      final source = PreviewNotificationsSource(
        mode: PreviewNotificationsMode.failed,
      );
      addTearDown(source.dispose);

      expect(
        () => source.loadPage(
          persona: Persona.admin,
          page: 0,
          pageSize: pageSize,
        ),
        throwsA(isA<NotificationsUnavailable>()),
      );
    });

    test('the offline mode answers once, then stops', () async {
      final source = PreviewNotificationsSource(
        mode: PreviewNotificationsMode.offline,
      );
      addTearDown(source.dispose);

      final feed = await source.loadPage(
        persona: Persona.admin,
        page: 0,
        pageSize: pageSize,
      );
      expect(feed.items, isNotEmpty);

      expect(
        () => source.loadPage(
          persona: Persona.admin,
          page: 0,
          pageSize: pageSize,
        ),
        throwsA(isA<NotificationsUnavailable>()),
      );
    });
  });
}
