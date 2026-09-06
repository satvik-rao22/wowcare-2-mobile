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

void main() {
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
}
