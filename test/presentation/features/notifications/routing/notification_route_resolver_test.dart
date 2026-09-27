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

/// A regularization push exactly as DEV sends it — captured from the
/// notification inbox response, not invented.
PushNotification _regularization({
  required String action,
  String staffCode = 'STF_C1A32C4F-B',
}) => PushNotification(
  title: 'Missed sign-out approved',
  body: 'Missed Sign out form is approved by the Admin for Sep 23, 2026',
  action: action,
  type: null,
  data: {
    'action': action,
    'module': 'ATTENDANCE',
    'staffCode': staffCode,
    'staffName': 'Mohan Staff',
    'regularizationCode': 'SREG_2FDA64C0-7',
    'attendanceDateIso': '2026-09-23',
  },
);

void main() {
  group('NotificationRouteResolver: regularization', () {
    test('opens the staff attendance profile on the Requests chip', () {
      final destination = NotificationRouteResolver.resolve(
        _regularization(action: 'STAFF_REGULARIZATION_APPROVED'),
      );

      expect(destination, isNotNull);
      expect(destination!.path, '/dashboard/staff-attendance-profile-by-code');
      expect(destination.queryParameters['code'], 'STF_C1A32C4F-B');
      // Without this the tap landed on All days, leaving the reader to hunt
      // for the request the notification was about.
      expect(destination.queryParameters['tab'], 'requests');
    });

    test('every regularization variant lands on the same chip', () {
      // Matched on the prefix, so a pending/edited variant the server adds
      // later routes correctly without a code change here.
      for (final action in [
        'STAFF_REGULARIZATION_APPROVED',
        'STAFF_REGULARIZATION_PENDING',
        'STAFF_REGULARIZATION_RAISED_SELF',
        'STAFF_REGULARIZATION_SOMETHING_NEW',
      ]) {
        final destination =
            NotificationRouteResolver.resolve(_regularization(action: action));
        expect(destination?.queryParameters['tab'], 'requests', reason: action);
      }
    });

    test('an ordinary attendance push still opens on All days', () {
      // The ATTENDANCE module fallback must not acquire a Requests chip.
      final destination = NotificationRouteResolver.resolve(
        _regularization(action: 'STAFF_SIGN_IN'),
      );

      expect(destination!.path, '/dashboard/staff-attendance-profile-by-code');
      expect(destination.queryParameters.containsKey('tab'), isFalse);
    });
  });

  group('NotificationRouteResolver: CLASSROOM_CHAT new-message routing', () {
    test(
      'a CLASSROOM_CHAT message with a classroomCode opens the Classroom '
      "screen's Notes tab (tab=2), not the standalone conversation thread",
      () {
        final destination = NotificationRouteResolver.resolve(
          _newMessage(const {
            'conversationCode': 'CONV_1',
            'conversationType': 'CLASSROOM_CHAT',
            'classroomCode': 'CLS_1',
          }),
        );

        expect(destination, isNotNull);
        expect(destination!.path, '/classroom-screen');
        expect(destination.queryParameters['tab'], '2');
        expect(destination.queryParameters['classroomCode'], 'CLS_1');
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
