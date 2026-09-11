import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';

PushNotification _activity(Map<String, String> data, {String? action}) =>
    PushNotification(
      title: 'title',
      body: 'body',
      action: action ?? 'ACTIVITY_RECORDED',
      type: 'ACTIVITY',
      data: data,
    );

/// An activity notification's destination must say WHICH CHILD it is about.
///
/// For a guardian the Activity Feed is scoped to the selected child, not to a
/// classroom, so a destination that carries only the card, the day and the room
/// is ambiguous for any parent with more than one child: two siblings in the
/// same room on the same day produce byte-identical locations.
void main() {
  group('activity deep-links carry their student', () {
    test('ACTIVITY_RECORDED includes studentCode from the payload', () {
      final destination = NotificationRouteResolver.resolve(
        _activity(const {
          'action': 'ACTIVITY_RECORDED',
          'cardGroupCode': 'ACG_1',
          'classroomCode': 'CLS_1',
          'studentCode': 'STD_B',
          'activityMarkedDate': '2026-09-05',
        }),
      );

      expect(destination, isNotNull);
      expect(destination!.path, '/activityFeed');
      expect(destination.queryParameters['studentCode'], 'STD_B');
      expect(destination.queryParameters['highlightCode'], 'ACG_1');
      expect(destination.queryParameters['classroomCode'], 'CLS_1');
      expect(destination.queryParameters['date'], '2026-09-05');
    });

    test('the snake_case payload variant is picked up too', () {
      final destination = NotificationRouteResolver.resolve(
        _activity(const {
          'action': 'INCIDENT_RECORDED',
          'cardGroupCode': 'ACG_9',
          'student_code': 'STD_A',
        }),
      );

      expect(destination!.queryParameters['studentCode'], 'STD_A');
    });

    test('the module fallback carries the student as well', () {
      // No `action` the table knows — routed by module. Parents hit this path
      // whenever the backend ships an activity event type the table predates.
      final destination = NotificationRouteResolver.resolve(
        _activity(const {
          'module': 'ACTIVITY',
          'cardGroupCode': 'ACG_2',
          'studentCode': 'STD_B',
        }, action: 'SOME_UNMAPPED_ACTIVITY_EVENT'),
      );

      expect(destination, isNotNull);
      expect(destination!.path, '/activityFeed');
      expect(destination.queryParameters['studentCode'], 'STD_B');
    });

    test('no student in the payload leaves the param off entirely', () {
      // A classroom-wide activity. The destination stays exactly as it was, so
      // the feed falls back to the currently selected child.
      final destination = NotificationRouteResolver.resolve(
        _activity(const {
          'action': 'ACTIVITY_RECORDED',
          'cardGroupCode': 'ACG_3',
          'classroomCode': 'CLS_1',
        }),
      );

      expect(destination!.queryParameters.containsKey('studentCode'), isFalse);
    });

    test(
      'two siblings, same card group, same day, same room → DIFFERENT locations',
      () {
        // This is the whole point: before the studentCode param these two were
        // byte-identical, so the second tap could not be told apart from the
        // first — not by the router, not by the feed's remount key.
        Map<String, String> payload(String student) => {
          'action': 'ACTIVITY_RECORDED',
          'cardGroupCode': 'ACG_1',
          'classroomCode': 'CLS_1',
          'activityMarkedDate': '2026-09-05',
          'studentCode': student,
        };

        final a = NotificationRouteResolver.resolve(
          _activity(payload('STD_A')),
        );
        final b = NotificationRouteResolver.resolve(
          _activity(payload('STD_B')),
        );

        expect(a!.location, isNot(b!.location));
      },
    );

    test('studentCodeFor and the destination agree on the child', () {
      final message = _activity(const {
        'action': 'ACTIVITY_RECORDED',
        'cardGroupCode': 'ACG_1',
        'studentCode': 'STD_B',
      });

      expect(
        NotificationRouteResolver.resolve(
          message,
        )!.queryParameters['studentCode'],
        NotificationRouteResolver.studentCodeFor(message),
      );
    });
  });
}
