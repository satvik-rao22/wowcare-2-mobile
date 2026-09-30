import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/push_notification.dart';
import 'package:wowcare/presentation/features/events/utils/holiday_year_window.dart';
import 'package:wowcare/presentation/features/events/view/events_screen.dart';
import 'package:wowcare/presentation/features/notifications/routing/notification_route_resolver.dart';

/// The two pure pieces the router uses to turn a holiday notification's query
/// string into Events-screen state: which tab to open, and whether the
/// requested year is one the Holiday List can actually show.
void main() {
  group('EventsTab.fromQueryValue', () {
    test('"holidays" opens the Holidays tab', () {
      expect(EventsTab.fromQueryValue('holidays'), EventsTab.holidays);
    });

    test('is tolerant of case and padding', () {
      expect(EventsTab.fromQueryValue(' Holidays '), EventsTab.holidays);
      expect(EventsTab.fromQueryValue('HOLIDAY'), EventsTab.holidays);
    });

    test('defaults to Events for null, empty and unknown values', () {
      // Existing event/task deep links carry no `tab` at all — they must keep
      // landing on the Events tab.
      expect(EventsTab.fromQueryValue(null), EventsTab.events);
      expect(EventsTab.fromQueryValue(''), EventsTab.events);
      expect(EventsTab.fromQueryValue('nonsense'), EventsTab.events);
      expect(EventsTab.fromQueryValue('events'), EventsTab.events);
    });
  });

  group('HolidayYearWindow', () {
    final now = DateTime(2026, 8, 6);

    test('offers the current year ±2, ascending (FR-HL-07/08)', () {
      expect(HolidayYearWindow.options(now), [2024, 2025, 2026, 2027, 2028]);
    });

    test('accepts a year inside the window', () {
      expect(HolidayYearWindow.contains(2028, now), isTrue);
      expect(HolidayYearWindow.contains(2024, now), isTrue);
    });

    test('rejects a year the selector could not display', () {
      // Out-of-window years are dropped rather than selected: the dropdown
      // falls back to showing the current year, so selecting one would leave
      // the list and the selector disagreeing.
      expect(HolidayYearWindow.contains(2029, now), isFalse);
      expect(HolidayYearWindow.contains(2023, now), isFalse);
    });

    test('spans whole years, so the bounds cover every selectable day', () {
      // The holiday form clamps its date picker to these, so an off-by-one
      // here would silently make 1 January or 31 December unpickable.
      expect(HolidayYearWindow.firstDate(now), DateTime(2024));
      expect(HolidayYearWindow.lastDate(now), DateTime(2028, 12, 31));
    });

    test('labels the range for validation messages', () {
      expect(HolidayYearWindow.label(now), '2024\u20132028');
    });
  });

  /// End-to-end over the whole deep link: notification payload → resolver →
  /// location string → the screen the router builds from its query map.
  group('payload → screen', () {
    EventsScreen screenFor(String action, Map<String, String> data) {
      final destination = NotificationRouteResolver.resolve(
        PushNotification(
          title: null,
          body: null,
          action: action,
          type: null,
          data: {'action': action, 'module': 'HOLIDAY', ...data},
        ),
      );
      // Exactly what the route does: parse the location go_router was given.
      final uri = Uri.parse(destination!.location);
      return EventsScreen.fromQuery(uri.queryParameters);
    }

    test('a created school holiday opens the Holidays tab on its year', () {
      final screen = screenFor('SCHOOL_HOLIDAY_CREATED', {
        'holidayName': 'Winter Break',
        'fromDate': '2026-12-21',
        'toDate': '2027-01-02',
      });

      expect(screen.initialTab, EventsTab.holidays);
      expect(screen.initialYear, 2026);
      expect(screen.highlightHolidayName, 'Winter Break');
    });

    test('a holiday name with spaces survives URL encoding', () {
      final screen = screenFor('FEDERAL_HOLIDAY_APPROVED', {
        'holidayName': "New Year's Day",
        'holidayDate': '2027-01-01 to 2027-01-01',
      });

      expect(screen.highlightHolidayName, "New Year's Day");
      expect(screen.initialYear, 2027);
    });

    test('a deleted holiday opens the tab with nothing to flash', () {
      final screen = screenFor('SCHOOL_HOLIDAY_DELETED', {
        'holidayName': 'Winter Break',
      });

      expect(screen.initialTab, EventsTab.holidays);
      expect(screen.highlightHolidayName, isNull);
      expect(screen.initialYear, isNull);
    });

    test('an event deep link still builds the default Events screen', () {
      final screen = EventsScreen.fromQuery(
        Uri.parse('/dashboard/events').queryParameters,
      );

      expect(screen.initialTab, EventsTab.events);
      expect(screen.initialYear, isNull);
      expect(screen.highlightHolidayName, isNull);
    });
  });
}
