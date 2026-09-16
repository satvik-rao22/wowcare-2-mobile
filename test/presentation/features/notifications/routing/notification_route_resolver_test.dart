import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';

PushNotification _newMessage(Map<String, String> data) => PushNotification(
  title: 'title',
  body: 'body',
  action: null,
  type: 'NEW_MESSAGE',
  data: data,
);

/// A newsletter push as the backend actually sends it: `module: NEWSLETTER`
/// plus org/school, and no newsletter-identifying code.
/// See `tools/NOTIFICATION_PAYLOADS.md`.
PushNotification _newsletter({required String action}) => PushNotification(
  title: 'title',
  body: 'body',
  action: action,
  type: null,
  data: const {
    'module': 'NEWSLETTER',
    'organizationCode': 'ORG_1',
    'schoolCode': 'SCH_1',
  },
);

void main() {
  group('NotificationRouteResolver: CLASSROOM_CHAT new-message routing', () {
    test(
      'a CLASSROOM_CHAT message with a classroomCode opens the Dashboard, '
      "focused on the Ratio Monitoring section, not the standalone "
      'conversation thread and not dropped directly into that one '
      "classroom's Notes tab",
      () {
        final destination = NotificationRouteResolver.resolve(
          _newMessage(const {
            'conversationCode': 'CONV_1',
            'conversationType': 'CLASSROOM_CHAT',
            'classroomCode': 'CLS_1',
          }),
        );

        expect(destination, isNotNull);
        expect(destination!.path, '/dashboard');
        expect(destination.queryParameters['focus'], 'ratioMonitoring');
        expect(destination.queryParameters['highlightCode'], 'CLS_1');
      },
    );

    test(
      'a CLASSROOM_CHAT message with no classroomCode falls back to the '
      "standalone conversation thread (can't build the classroom destination)",
      () {
        final destination = NotificationRouteResolver.resolve(
          _newMessage(const {
            'conversationCode': 'CONV_1',
            'conversationType': 'CLASSROOM_CHAT',
          }),
        );

        expect(destination, isNotNull);
        expect(destination!.path, '/open-conversation');
        expect(destination.queryParameters['conversationCode'], 'CONV_1');
      },
    );

    test('a non-CLASSROOM_CHAT message (e.g. a room/parent chat) still opens '
        'the standalone conversation thread, unaffected by this routing', () {
      final destination = NotificationRouteResolver.resolve(
        _newMessage(const {
          'conversationCode': 'CONV_1',
          'conversationType': 'ROOM_CHAT',
          'classroomCode': 'CLS_1',
        }),
      );

      expect(destination, isNotNull);
      expect(destination!.path, '/open-conversation');
      expect(destination.queryParameters['conversationCode'], 'CONV_1');
      expect(destination.queryParameters['conversationType'], 'ROOM_CHAT');
    });
  });

  group('NotificationRouteResolver: ADD_CLASSROOM_NOTE routing', () {
    test(
      'an ADD_CLASSROOM_NOTE push opens the Dashboard, focused on the Ratio '
      'Monitoring section',
      () {
        final destination = NotificationRouteResolver.resolve(
          PushNotification(
            title: 'title',
            body: 'body',
            action: 'ADD_CLASSROOM_NOTE',
            type: null,
            data: const {'classroomCode': 'CLS_1'},
          ),
        );

        expect(destination, isNotNull);
        expect(destination!.path, '/dashboard');
        expect(destination.queryParameters['focus'], 'ratioMonitoring');
        expect(destination.queryParameters['highlightCode'], 'CLS_1');
      },
    );
  });

  group('NotificationRouteResolver: newsletter routing', () {
    // Guardians have no Newsletter tab — `MessagingScreen` builds the
    // Messaging/Newsletter TabBar only for staff/admin and gives parents
    // ParentDirectMessagingScreen (room chat). So `/messageFeed?tab=newsletter`
    // silently dropped them on room chat; their list is its own screen.
    const parentNewsletter = '/dashboard/parent-newsletter';

    test('a NEWSLETTER_SENT tap by a guardian opens the parent newsletter '
        'screen, NOT the messaging branch', () {
      final destination = NotificationRouteResolver.resolve(
        _newsletter(action: 'NEWSLETTER_SENT'),
        isGuardian: true,
      );

      expect(destination, isNotNull);
      expect(destination!.path, parentNewsletter);
    });

    test('the NEWSLETTER_RECEIVED alias routes a guardian the same way', () {
      final destination = NotificationRouteResolver.resolve(
        _newsletter(action: 'NEWSLETTER_RECEIVED'),
        isGuardian: true,
      );

      expect(destination, isNotNull);
      expect(destination!.path, parentNewsletter);
    });

    test('a guardian newsletter push with an UNKNOWN action still lands on the '
        'parent newsletter screen via the NEWSLETTER module fallback', () {
      final destination = NotificationRouteResolver.resolve(
        _newsletter(action: 'NEWSLETTER_SOMETHING_NEW'),
        isGuardian: true,
      );

      expect(destination, isNotNull);
      expect(destination!.path, parentNewsletter);
    });

    test('staff still get the messaging branch Newsletter tab', () {
      final destination = NotificationRouteResolver.resolve(
        _newsletter(action: 'NEWSLETTER_SENT'),
      );

      expect(destination, isNotNull);
      expect(destination!.path, '/messageFeed');
      expect(destination.queryParameters['tab'], 'newsletter');
    });

    test('the NEWSLETTER module fallback carries tab=newsletter for staff — it '
        'used to return a bare /messageFeed, opening the Messaging tab', () {
      final destination = NotificationRouteResolver.resolve(
        _newsletter(action: 'NEWSLETTER_SOMETHING_NEW'),
      );

      expect(destination, isNotNull);
      expect(destination!.path, '/messageFeed');
      expect(destination.queryParameters['tab'], 'newsletter');
    });

    test('a MESSAGING-module push is unaffected and stays on /messageFeed with '
        'no tab override', () {
      final destination = NotificationRouteResolver.resolve(
        PushNotification(
          title: 'title',
          body: 'body',
          action: 'SOMETHING_UNMAPPED',
          type: null,
          data: const {'module': 'MESSAGING'},
        ),
        isGuardian: true,
      );

      expect(destination, isNotNull);
      expect(destination!.path, '/messageFeed');
      expect(destination.queryParameters['tab'], isNull);
    });

    test('an admin with a newsletterCode still deep-links to that newsletter, '
        'ahead of any list screen', () {
      final destination = NotificationRouteResolver.resolve(
        PushNotification(
          title: 'title',
          body: 'body',
          action: 'NEWSLETTER_SENT',
          type: null,
          data: const {'module': 'NEWSLETTER', 'newsletterCode': 'NL_1'},
        ),
        isAdminPersona: true,
      );

      expect(destination, isNotNull);
      expect(destination!.path, '/newsletter-preview-by-code');
      expect(destination.queryParameters['code'], 'NL_1');
    });
  });
}
