import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/events/models/event_models.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';

Event _event({
  EventType type = EventType.classroom,
  String name = 'Morning circle',
  DateTime? date,
  bool allDay = false,
  String startTime = '09:00',
  String endTime = '09:30',
  String description = '',
  List<EventAttendee> classrooms = const [],
  List<EventAttendee> students = const [],
  List<EventAttendee> staff = const [],
  bool includeParents = false,
  bool recurring = false,
  EventRecurrence? recurringPattern,
  DateTime? recurringEndDate,
}) {
  return Event(
    code: '',
    type: type,
    name: name,
    date: date ?? DateTime(2026, 9, 10),
    allDay: allDay,
    startTime: allDay ? '' : startTime,
    endTime: allDay ? '' : endTime,
    description: description,
    classrooms: classrooms,
    students: students,
    staff: staff,
    includeParents: includeParents,
    recurring: recurring,
    recurringPattern: recurringPattern,
    recurringEndDate: recurringEndDate,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
  );
}

void main() {
  group('EventModel.createBody', () {
    test('school event sends the single SCHOOL_WIDE selector', () {
      final body = EventModel.createBody(
        _event(
          type: EventType.school,
          // The form snapshots every classroom for school events; the
          // payload must ignore them — the server expands SCHOOL_WIDE.
          classrooms: const [EventAttendee(code: 'CLS_A', name: 'Bumblebees')],
          includeParents: true,
        ),
      );

      expect(body['type'], 'SCHOOL');
      expect(body['audienceScope'], 'SCHOOL');
      expect(body['audiences'], [
        {'selectorKind': 'SCHOOL_WIDE'},
      ]);
      expect(body['includeParentsFlag'], isTrue);
    });

    test('classroom multiselect maps to CLASSROOM_SET selectors', () {
      final body = EventModel.createBody(
        _event(
          classrooms: const [
            EventAttendee(code: 'CLS_A', name: 'Bumblebees'),
            EventAttendee(code: 'CLS_B', name: 'Fireflies'),
          ],
        ),
      );

      expect(body['audienceScope'], 'CLASSROOM_SET');
      expect(body['audiences'], [
        {'selectorKind': 'CLASSROOM', 'selectorCode': 'CLS_A'},
        {'selectorKind': 'CLASSROOM', 'selectorCode': 'CLS_B'},
      ]);
    });

    test('timed event sends HH:mm:ss; all-day omits times', () {
      final timed = EventModel.createBody(_event());
      expect(timed['seriesStartDate'], '2026-09-10');
      expect(timed['seriesStartTime'], '09:00:00');
      expect(timed['seriesEndTime'], '09:30:00');
      expect(timed['allDayFlag'], isFalse);

      final allDay = EventModel.createBody(_event(allDay: true));
      expect(allDay['allDayFlag'], isTrue);
      expect(allDay.containsKey('seriesStartTime'), isFalse);
      expect(allDay.containsKey('seriesEndTime'), isFalse);
    });

    test('non-recurring event carries no rrule', () {
      final body = EventModel.createBody(_event());
      expect(body['recurringFlag'], isFalse);
      expect(body.containsKey('rrule'), isFalse);
    });

    test('recurring daily/weekly/monthly encode the contract RRULEs', () {
      Map<String, dynamic> body(EventRecurrence pattern) =>
          EventModel.createBody(
            _event(
              date: DateTime(2026, 9, 15),
              recurring: true,
              recurringPattern: pattern,
              recurringEndDate: DateTime(2026, 12, 18),
            ),
          );

      expect(
        body(EventRecurrence.daily)['rrule'],
        'FREQ=DAILY;UNTIL=20261218',
      );
      expect(
        body(EventRecurrence.weekly)['rrule'],
        'FREQ=WEEKLY;UNTIL=20261218',
      );
      expect(
        body(EventRecurrence.monthly)['rrule'],
        'FREQ=MONTHLY;BYMONTHDAY=15;UNTIL=20261218',
      );
    });

    test('custom and individual events send mixed CUSTOM selectors', () {
      final body = EventModel.createBody(
        _event(
          type: EventType.individual,
          students: const [EventAttendee(code: 'STD_A', name: 'Emma')],
          staff: const [EventAttendee(code: 'STF_A', name: 'Ms. Lee')],
        ),
      );

      expect(body['audienceScope'], 'CUSTOM');
      expect(body['audiences'], [
        {'selectorKind': 'STUDENT', 'selectorCode': 'STD_A'},
        {'selectorKind': 'STAFF', 'selectorCode': 'STF_A'},
      ]);
    });

    test('empty description is omitted', () {
      expect(
        EventModel.createBody(_event()).containsKey('description'),
        isFalse,
      );
      expect(
        EventModel.createBody(_event(description: 'Bring snacks'))['description'],
        'Bring snacks',
      );
    });
  });

  group('EventModel.fromApi', () {
    test('parses the contract create response (§4.3)', () {
      final model = EventModel.fromApi({
        'code': 'EVT_A1B2C3D4',
        'type': 'STUDENT',
        'name': 'Storytelling group',
        'description': 'Weekly reading circle',
        'seriesStartDate': '2026-09-10',
        'seriesStartTime': '13:00:00',
        'seriesEndTime': '13:30:00',
        'allDayFlag': false,
        'audienceScope': 'STUDENT_SET',
        'includeParentsFlag': true,
        'recurringFlag': false,
        'rrule': null,
        'version': 0,
        'audiences': [
          {'selectorKind': 'STUDENT', 'selectorCode': 'STD_EMMA'},
          {'selectorKind': 'STUDENT', 'selectorCode': 'STD_LIAM'},
        ],
      });

      expect(model.code, 'EVT_A1B2C3D4');
      expect(model.type, 'STUDENT');
      expect(model.date, DateTime(2026, 9, 10));
      // Times are normalized to HH:mm — the edit form's parser rejects
      // seconds and would silently fall back to defaults otherwise.
      expect(model.startTime, '13:00');
      expect(model.endTime, '13:30');
      expect(model.includeParents, isTrue);
      expect(model.version, 0);
      expect(model.students.map((s) => s.code), ['STD_EMMA', 'STD_LIAM']);
      expect(model.classrooms, isEmpty);

      final entity = model.toEntity();
      expect(entity.type, EventType.student);
      expect(entity.version, 0);
    });

    test('parses recurring fields from the rrule', () {
      final model = EventModel.fromApi({
        'code': 'EVT_1',
        'type': 'SCHOOL',
        'name': 'Weekly assembly',
        'seriesStartDate': '2026-09-07',
        'allDayFlag': true,
        'recurringFlag': true,
        'rrule': 'FREQ=WEEKLY;BYDAY=MO;UNTIL=20261218T235959Z',
        'audiences': [
          {'selectorKind': 'SCHOOL_WIDE'},
        ],
      });

      expect(model.recurring, isTrue);
      expect(model.recurringPattern, 'WEEKLY');
      expect(model.recurringEndDate, DateTime(2026, 12, 18));
      // SCHOOL_WIDE carries no selector code — no phantom attendees.
      expect(model.classrooms, isEmpty);
    });

    test('prefers the explicit rruleUntil over the RRULE token', () {
      final model = EventModel.fromApi({
        'code': 'EVT_1',
        'type': 'SCHOOL',
        'name': 'Assembly',
        'seriesStartDate': '2026-09-07',
        'recurringFlag': true,
        'rrule': 'FREQ=DAILY;UNTIL=20261001',
        'rruleUntil': '2026-11-01',
      });

      expect(model.recurringEndDate, DateTime(2026, 11, 1));
    });

    test('unsupported YEARLY frequency degrades to no pattern', () {
      final model = EventModel.fromApi({
        'code': 'EVT_1',
        'type': 'SCHOOL',
        'name': 'Anniversary',
        'seriesStartDate': '2026-10-04',
        'recurringFlag': true,
        'rrule': 'FREQ=YEARLY;UNTIL=20361004',
      });

      expect(model.recurringPattern, isNull);
      expect(model.toEntity().recurringPattern, isNull);
    });
  });
}
