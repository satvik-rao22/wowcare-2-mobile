import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
import 'package:wowcare/presentation/features/events/view_model/events_cubit.dart';

/// The calendar feed mixes EVENT, TASK and HOLIDAY rows, so `CALENDAR` read
/// alone must not surface rows from modules the user has no access to.
/// [EventsState.calendarItemsOn] takes the readable kinds and is the single
/// choke point every calendar surface goes through.

CalendarFeedItem _item(CalendarFeedKind kind, String code) => CalendarFeedItem(
  kind: kind,
  code: code,
  name: code,
  date: DateTime(2026, 7, 15),
  allDay: true,
);

void main() {
  final day = DateTime(2026, 7, 15);
  final items = <CalendarFeedItem>[
    _item(CalendarFeedKind.event, 'EVT'),
    _item(CalendarFeedKind.task, 'TSK'),
    _item(CalendarFeedKind.holiday, 'HOL'),
  ];
  final state = EventsState.initial().copyWith(calendarItems: items);

  List<String> codesFor(Set<CalendarFeedKind> allowed) => state
      .calendarItemsOn(day, allowedKinds: allowed)
      .map((i) => i.code)
      .toList();

  test('only rows whose module is readable are returned', () {
    expect(codesFor({CalendarFeedKind.event}), <String>['EVT']);
    expect(codesFor({CalendarFeedKind.holiday}), <String>['HOL']);
    expect(
      codesFor({CalendarFeedKind.event, CalendarFeedKind.task}),
      containsAll(<String>['EVT', 'TSK']),
    );
  });

  test('no readable kinds yields nothing, not everything', () {
    expect(codesFor(const <CalendarFeedKind>{}), isEmpty);
    expect(state.calendarHasItems(day, allowedKinds: const {}), isFalse);
  });

  test('module access is checked before the UI kind filter', () {
    // The user filtered the calendar to Tasks but has no TASK access: the
    // filter must not be able to widen what the permission allows.
    final filtered = state.copyWith(
      calendarKindFilter: {CalendarFeedKind.task},
    );
    expect(
      filtered
          .calendarItemsOn(day, allowedKinds: {CalendarFeedKind.event})
          .map((i) => i.code),
      isEmpty,
    );
  });
}
