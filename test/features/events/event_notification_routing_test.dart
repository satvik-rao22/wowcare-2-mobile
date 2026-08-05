import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';

/// The Events push-notification contract, client side: all 6 `EVENT_*`
/// actions must resolve, and — unlike Tasks — every one of them carries the
/// real `eventCode` directly, so there's no series/assignment split to
/// resolve locally.
void main() {
  const org = 'ORG_67F60097-C';
  const school = 'SCH_74709D20-7';
  const event = 'EVT_A1B2C3D4';

  PushNotification push(String action, Map<String, String> extra) =>
      PushNotification(
        title: null,
        body: null,
        action: action,
        type: null,
        data: <String, String>{
          'action': action,
          'module': 'EVENTS',
          'organizationCode': org,
          'schoolCode': school,
          ...extra,
        },
      );

  group('resolver — all pushing + in-app-only actions open the event card',
      () {
    for (final action in const [
      'EVENT_INVITED',
      'EVENT_UPDATED',
      'EVENT_REMINDER_TOMORROW',
      'EVENT_RSVP_REMINDER',
      'EVENT_RSVP_SUBMITTED',
    ]) {
      test('$action → detail with eventCode', () {
        final dest = NotificationRouteResolver.resolve(push(action, {
          'eventCode': event,
          'eventName': 'Sports Day',
        }));

        expect(dest, isNotNull);
        expect(dest!.path, '/dashboard/events/detail');
        expect(dest.queryParameters['eventCode'], event);
      });
    }
  });

  test('EVENT_DELETED → the list, since the card no longer exists', () {
    final dest = NotificationRouteResolver.resolve(push('EVENT_DELETED', {
      'eventCode': event,
      'eventName': 'Sports Day',
    }));

    expect(dest, isNotNull);
    expect(dest!.path, '/dashboard/events');
  });

  test('a push with no eventCode falls back to the list, not an empty card',
      () {
    final dest = NotificationRouteResolver.resolve(
      push('EVENT_INVITED', {'eventName': 'Sports Day'}),
    );

    expect(dest, isNotNull);
    expect(dest!.path, '/dashboard/events');
  });

  test('snake_case eventCode resolves as well as camelCase', () {
    final dest = NotificationRouteResolver.resolve(
      push('EVENT_UPDATED', {'event_code': event}),
    );

    expect(dest!.queryParameters['eventCode'], event);
  });

  test('the EVENT_INVITED staff vs parent copy split does not affect routing',
      () {
    final staffDest = NotificationRouteResolver.resolve(push('EVENT_INVITED', {
      'eventCode': event,
      'role': 'STAFF',
    }));
    final parentDest =
        NotificationRouteResolver.resolve(push('EVENT_INVITED', {
      'eventCode': event,
      'role': 'GUARDIAN',
    }));

    expect(staffDest!.location, parentDest!.location);
  });

  test('bulk audience fields in the payload are ignored, not routed on', () {
    final dest = NotificationRouteResolver.resolve(push('EVENT_INVITED', {
      'eventCode': event,
      'recipients': '["USR_1","USR_2","USR_3"]',
      'audience': 'SCHOOL_WIDE',
      'recipientStrategy': 'BULK',
    }));

    expect(dest!.path, '/dashboard/events/detail');
    expect(dest.queryParameters.length, 1);
    expect(dest.queryParameters['eventCode'], event);
  });

  group('module fallback — EVENTS/TASKS route even without an exact action match',
      () {
    test('an unrecognised EVENTS action still opens the event card', () {
      final dest = NotificationRouteResolver.resolve(push('EVENT_SOMETHING_NEW', {
        'eventCode': event,
        'module': 'EVENTS',
      }));

      expect(dest, isNotNull);
      expect(dest!.path, '/dashboard/events/detail');
    });
  });
}
