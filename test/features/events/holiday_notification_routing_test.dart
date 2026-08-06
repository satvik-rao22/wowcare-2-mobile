import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';

/// The Holidays push-notification contract, client side
/// (PUSH_CONTRACT_HOLIDAYS).
///
/// Holidays differ from Events and Tasks in one decisive way: the payload
/// carries **no holiday entity code**, so there is nothing to deep-link to a
/// single record — and the app has no individual-holiday detail screen either.
/// Every holiday action therefore opens the **Holiday List** (the Events
/// screen's Holidays tab), scoped to the holiday's year and flashing the named
/// card where the payload names one.
void main() {
  const org = 'ORG_67F60097-C';
  const school = 'SCH_74709D20-7';

  /// The Holiday List is a tab of the Events screen, not a route of its own.
  const holidayList = '/dashboard/events';

  PushNotification push(String action, Map<String, String> extra) =>
      PushNotification(
        title: null,
        body: null,
        action: action,
        type: null,
        data: <String, String>{
          'action': action,
          'module': 'HOLIDAY',
          'organizationCode': org,
          'schoolCode': school,
          ...extra,
        },
      );

  group('every holiday action opens the Holiday List', () {
    for (final action in const [
      'SCHOOL_HOLIDAY_CREATED',
      'SCHOOL_HOLIDAY_DELETED',
      'FEDERAL_HOLIDAY_APPROVED',
      'FEDERAL_HOLIDAYS_REVIEW',
    ]) {
      test('$action → the Holidays tab', () {
        final dest = NotificationRouteResolver.resolve(
          push(action, {'holidayName': 'Winter Break', 'year': '2027'}),
        );

        expect(dest, isNotNull);
        expect(dest!.path, holidayList);
        expect(dest.queryParameters['tab'], 'holidays');
      });
    }
  });

  group('SCHOOL_HOLIDAY_CREATED', () {
    test('flashes the created holiday and opens its year', () {
      final dest = NotificationRouteResolver.resolve(
        push('SCHOOL_HOLIDAY_CREATED', {
          'holidayName': 'Winter Break',
          'fromDate': '2026-12-21',
          'toDate': '2027-01-02',
        }),
      );

      expect(dest!.queryParameters['highlightHoliday'], 'Winter Break');
      // The list filters by START year, so a holiday spanning the new year is
      // found under fromDate's year — not toDate's.
      expect(dest.queryParameters['year'], '2026');
    });

    test('snake_case keys resolve as well as camelCase', () {
      final dest = NotificationRouteResolver.resolve(
        push('SCHOOL_HOLIDAY_CREATED', {
          'holiday_name': 'Founders Day',
          'from_date': '2026-05-04',
        }),
      );

      expect(dest!.queryParameters['highlightHoliday'], 'Founders Day');
      expect(dest.queryParameters['year'], '2026');
    });
  });

  test('SCHOOL_HOLIDAY_DELETED opens the plain list — the card is gone', () {
    final dest = NotificationRouteResolver.resolve(
      push('SCHOOL_HOLIDAY_DELETED', {'holidayName': 'Winter Break'}),
    );

    expect(dest!.path, holidayList);
    // Nothing to flash and no date in the payload: only the tab.
    expect(dest.queryParameters, {'tab': 'holidays'});
  });

  test(
    'FEDERAL_HOLIDAY_APPROVED reads the year out of its date RANGE string',
    () {
      final dest = NotificationRouteResolver.resolve(
        push('FEDERAL_HOLIDAY_APPROVED', {
          'holidayName': 'Christmas Day',
          // Contract: `holidayDate` is a range, not a single date.
          'holidayDate': '2026-12-25 to 2026-12-25',
        }),
      );

      expect(dest!.queryParameters['highlightHoliday'], 'Christmas Day');
      expect(dest.queryParameters['year'], '2026');
    },
  );

  test('FEDERAL_HOLIDAYS_REVIEW opens the reviewed year, with no card to flash',
      () {
    final dest = NotificationRouteResolver.resolve(
      push('FEDERAL_HOLIDAYS_REVIEW', {
        'year': '2027',
        'count': '11',
        'schoolName': 'Wise Owl Academy',
      }),
    );

    expect(dest!.queryParameters['year'], '2027');
    expect(dest.queryParameters.containsKey('highlightHoliday'), isFalse);
  });

  group('degraded payloads still land on the list', () {
    test('no name and no date at all', () {
      final dest = NotificationRouteResolver.resolve(
        push('SCHOOL_HOLIDAY_CREATED', const {}),
      );

      expect(dest!.path, holidayList);
      expect(dest.queryParameters, {'tab': 'holidays'});
    });

    test('an unparseable date is dropped rather than routed on', () {
      final dest = NotificationRouteResolver.resolve(
        push('SCHOOL_HOLIDAY_CREATED', {
          'holidayName': 'Odd One',
          'fromDate': 'next tuesday',
        }),
      );

      expect(dest!.queryParameters.containsKey('year'), isFalse);
      expect(dest.queryParameters['highlightHoliday'], 'Odd One');
    });

    test('a whitespace-only holidayName is not treated as a name', () {
      final dest = NotificationRouteResolver.resolve(
        push('SCHOOL_HOLIDAY_CREATED', {'holidayName': '   '}),
      );

      expect(dest!.queryParameters.containsKey('highlightHoliday'), isFalse);
    });
  });

  test('module HOLIDAY routes even when the action is not in the table yet',
      () {
    final dest = NotificationRouteResolver.resolve(
      push('SCHOOL_HOLIDAY_SOMETHING_NEW', {'holidayName': 'Winter Break'}),
    );

    expect(dest, isNotNull);
    expect(dest!.path, holidayList);
    expect(dest.queryParameters['tab'], 'holidays');
  });

  test('an in-app (bell) holiday item resolves through the same table', () {
    final dest = NotificationRouteResolver.resolveData(<String, String>{
      'action': 'FEDERAL_HOLIDAY_APPROVED',
      'module': 'HOLIDAY',
      'holidayName': 'Labor Day',
      'holidayDate': '2026-09-07 to 2026-09-07',
    });

    expect(dest!.path, holidayList);
    expect(dest.queryParameters['highlightHoliday'], 'Labor Day');
    expect(dest.queryParameters['year'], '2026');
  });

  group('regression: Events and Tasks routing is untouched', () {
    test('EVENT_INVITED still opens the event detail card', () {
      final dest = NotificationRouteResolver.resolve(
        PushNotification(
          title: null,
          body: null,
          action: 'EVENT_INVITED',
          type: null,
          data: const {
            'action': 'EVENT_INVITED',
            'module': 'EVENTS',
            'eventCode': 'EVT_A1B2C3D4',
          },
        ),
      );

      expect(dest!.path, '/dashboard/events/detail');
      expect(dest.queryParameters['eventCode'], 'EVT_A1B2C3D4');
      expect(dest.queryParameters.containsKey('tab'), isFalse);
    });

    test('EVENT_DELETED still opens the Events list on its EVENTS tab', () {
      final dest = NotificationRouteResolver.resolve(
        PushNotification(
          title: null,
          body: null,
          action: 'EVENT_DELETED',
          type: null,
          data: const {'action': 'EVENT_DELETED', 'module': 'EVENTS'},
        ),
      );

      expect(dest!.path, '/dashboard/events');
      // No `tab` param means the screen opens on its default (Events) tab —
      // a holiday deep link must not have changed that.
      expect(dest.queryParameters.containsKey('tab'), isFalse);
    });

    test('TASK_ASSIGNED still opens the task detail card', () {
      final dest = NotificationRouteResolver.resolve(
        PushNotification(
          title: null,
          body: null,
          action: 'TASK_ASSIGNED',
          type: null,
          data: const {
            'action': 'TASK_ASSIGNED',
            'type': 'TASK',
            'taskCode': 'TSK_1234',
          },
        ),
      );

      expect(dest!.path, '/dashboard/tasks/detail');
      expect(dest.queryParameters['seriesCode'], 'TSK_1234');
    });
  });
}
