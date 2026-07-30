import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/events/models/calendar_feed_models.dart';
import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';

void main() {
  group('CalendarFeedItemModel.fromApi', () {
    // Tasks and events use DIFFERENT field schemas in the same feed —
    // the parser must accept both or task rows silently disappear.
    test('parses a TASK row (title/occurrenceDate/startTime schema)', () {
      final item = CalendarFeedItemModel.fromApi({
        'type': 'TASK',
        'code': 'TSA_976C01F5C9',
        'status': 'TO_DO',
        'taskCode': 'TSK_D2D2FE7495',
        'title': 'Mobile task',
        'description': 'Hello all, this is mobile task.',
        'assigneeCode': 'STF_07A3BACE-B',
        'occurrenceDate': '2026-08-01',
        'startTime': '13:00:00',
        'dueDate': '2026-08-01',
        'dueTime': '21:00:00',
        'priority': 'MEDIUM',
        'overdue': false,
      })!;

      expect(item.kind, CalendarFeedKind.task);
      expect(item.code, 'TSA_976C01F5C9');
      expect(item.taskCode, 'TSK_D2D2FE7495');
      expect(item.name, 'Mobile task');
      expect(item.date, DateTime(2026, 8, 1));
      expect(item.startTime, '13:00');
      expect(item.endTime, '21:00');
      expect(item.allDay, isFalse);
      expect(item.assigneeCode, 'STF_07A3BACE-B');
      expect(item.priority, 'MEDIUM');
      expect(item.overdue, isFalse);
    });

    test('a task without a start time is treated as all-day', () {
      final item = CalendarFeedItemModel.fromApi({
        'type': 'TASK',
        'code': 'TSA_1',
        'title': 'No time task',
        'occurrenceDate': '2026-08-02',
      })!;
      expect(item.allDay, isTrue);
    });

    test('parses an EVENT row (displayName/scheduledStartDate schema)', () {
      final item = CalendarFeedItemModel.fromApi({
        'type': 'EVENT',
        'code': 'OCC_1',
        'eventCode': 'EVT_1',
        'displayName': 'Sports Day',
        'scheduledStartDate': '2026-08-16',
        'scheduledStartTime': '09:00:00',
        'scheduledEndTime': '16:00:00',
        'allDayFlag': false,
        'eventType': 'SCHOOL',
        'colorHint': '#2563EB',
        'rsvpSummary': {'attending': 58, 'totalAttendee': 74},
        'participantCounts': {'staff': 22, 'students': 28, 'parents': 26},
      })!;

      expect(item.kind, CalendarFeedKind.event);
      expect(item.eventCode, 'EVT_1');
      expect(item.name, 'Sports Day');
      expect(item.startTime, '09:00');
      expect(item.attendingCount, 58);
      expect(item.totalAttendee, 74);
      expect(item.staffCount, 22);
    });

    test('parses a HOLIDAY row', () {
      final item = CalendarFeedItemModel.fromApi({
        'type': 'HOLIDAY',
        'code': 'HOL_1',
        'displayName': 'Date Range Holiday',
        'scheduledStartDate': '2026-08-10',
        'allDayFlag': true,
        'holidayType': 'SCHOOL',
      })!;
      expect(item.kind, CalendarFeedKind.holiday);
      expect(item.allDay, isTrue);
      expect(item.holidayType, 'SCHOOL');
    });

    test('rows without a code or a date are dropped', () {
      expect(
        CalendarFeedItemModel.fromApi({'type': 'TASK', 'title': 'x'}),
        isNull,
      );
      expect(
        CalendarFeedItemModel.fromApi({'code': 'X_1', 'type': 'TASK'}),
        isNull,
      );
    });

    test('unknown kinds parse as unknown (birthdays, important dates)', () {
      final item = CalendarFeedItemModel.fromApi({
        'type': 'BIRTHDAY',
        'code': 'BD_1',
        'displayName': 'Emma turns 5',
        'scheduledStartDate': '2026-08-04',
      })!;
      expect(item.kind, CalendarFeedKind.unknown);
    });
  });
}
