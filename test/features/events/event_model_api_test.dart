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
  RecurrenceRule? recurrence,
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
    recurrence: recurrence,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
  );
}

Event _recurring(
  RecurrenceFrequency frequency, {
  DateTime? date,
  int interval = 1,
  Set<int> daysOfWeek = const {},
  MonthlyRepeatMode monthlyMode = MonthlyRepeatMode.dayOfMonth,
  YearlyRepeatMode yearlyMode = YearlyRepeatMode.date,
}) {
  return _event(
    date: date ?? DateTime(2026, 9, 15), // a Tuesday
    recurring: true,
    recurrence: RecurrenceRule(
      frequency: frequency,
      interval: interval,
      daysOfWeek: daysOfWeek,
      monthlyMode: monthlyMode,
      yearlyMode: yearlyMode,
      endDate: DateTime(2026, 12, 18),
    ),
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

  group('EventModel.buildRrule', () {
    test('daily every day', () {
      expect(
        EventModel.buildRrule(_recurring(RecurrenceFrequency.daily)),
        'FREQ=DAILY;UNTIL=20261218',
      );
    });

    test('daily every 3 days carries INTERVAL', () {
      expect(
        EventModel.buildRrule(
          _recurring(RecurrenceFrequency.daily, interval: 3),
        ),
        'FREQ=DAILY;INTERVAL=3;UNTIL=20261218',
      );
    });

    test('daily on a weekday subset becomes weekly BYDAY (Teams semantics)',
        () {
      expect(
        EventModel.buildRrule(
          _recurring(
            RecurrenceFrequency.daily,
            daysOfWeek: {DateTime.monday, DateTime.wednesday},
          ),
        ),
        'FREQ=WEEKLY;BYDAY=MO,WE;UNTIL=20261218',
      );
    });

    test('weekly defaults to the start weekday when no days picked', () {
      expect(
        EventModel.buildRrule(_recurring(RecurrenceFrequency.weekly)),
        'FREQ=WEEKLY;BYDAY=TU;UNTIL=20261218', // 2026-09-15 is a Tuesday
      );
    });

    test('every 2 weeks on Mon, Wed, Fri', () {
      expect(
        EventModel.buildRrule(
          _recurring(
            RecurrenceFrequency.weekly,
            interval: 2,
            daysOfWeek: {
              DateTime.monday,
              DateTime.wednesday,
              DateTime.friday,
            },
          ),
        ),
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;UNTIL=20261218',
      );
    });

    test('monthly by day of month', () {
      expect(
        EventModel.buildRrule(_recurring(RecurrenceFrequency.monthly)),
        'FREQ=MONTHLY;BYMONTHDAY=15;UNTIL=20261218',
      );
    });

    test('monthly on the nth weekday', () {
      expect(
        EventModel.buildRrule(
          _recurring(
            RecurrenceFrequency.monthly,
            monthlyMode: MonthlyRepeatMode.nthWeekday,
          ),
        ),
        // Sep 15, 2026 is the third Tuesday.
        'FREQ=MONTHLY;BYDAY=3TU;UNTIL=20261218',
      );
    });

    test('monthly on the LAST weekday uses the -1 ordinal', () {
      expect(
        EventModel.buildRrule(
          _recurring(
            RecurrenceFrequency.monthly,
            date: DateTime(2026, 9, 29), // last Tuesday of Sep 2026
            monthlyMode: MonthlyRepeatMode.nthWeekday,
          ),
        ),
        'FREQ=MONTHLY;BYDAY=-1TU;UNTIL=20261218',
      );
    });

    test('yearly by date anchors month and day', () {
      expect(
        EventModel.buildRrule(
          _recurring(RecurrenceFrequency.yearly, interval: 2),
        ),
        'FREQ=YEARLY;INTERVAL=2;BYMONTH=9;BYMONTHDAY=15;UNTIL=20261218',
      );
    });

    test('yearly on the nth weekday of the month', () {
      expect(
        EventModel.buildRrule(
          _recurring(
            RecurrenceFrequency.yearly,
            yearlyMode: YearlyRepeatMode.nthWeekday,
          ),
        ),
        'FREQ=YEARLY;BYMONTH=9;BYDAY=3TU;UNTIL=20261218',
      );
    });
  });

  group('EventModel.parseRrule', () {
    test('round-trips a weekly interval rule', () {
      final rule = EventModel.parseRrule(
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE,FR;UNTIL=20261218',
      )!;

      expect(rule.frequency, RecurrenceFrequency.weekly);
      expect(rule.interval, 2);
      expect(
        rule.daysOfWeek,
        {DateTime.monday, DateTime.wednesday, DateTime.friday},
      );
      expect(rule.endDate, DateTime(2026, 12, 18));
    });

    test('ordinal BYDAY parses as nth-weekday mode, not a weekday set', () {
      final rule = EventModel.parseRrule('FREQ=MONTHLY;BYDAY=-1FR')!;

      expect(rule.frequency, RecurrenceFrequency.monthly);
      expect(rule.monthlyMode, MonthlyRepeatMode.nthWeekday);
      expect(rule.daysOfWeek, isEmpty);
      expect(rule.endDate, isNull);
    });

    test('yearly nth-weekday parses both modes', () {
      final rule =
          EventModel.parseRrule('FREQ=YEARLY;BYMONTH=9;BYDAY=3TU')!;
      expect(rule.frequency, RecurrenceFrequency.yearly);
      expect(rule.yearlyMode, YearlyRepeatMode.nthWeekday);

      final byDate = EventModel.parseRrule(
        'FREQ=YEARLY;BYMONTH=9;BYMONTHDAY=15',
      )!;
      expect(byDate.yearlyMode, YearlyRepeatMode.date);
    });

    test('unknown FREQ yields null', () {
      expect(EventModel.parseRrule('FREQ=HOURLY;UNTIL=20261218'), isNull);
      expect(EventModel.parseRrule(''), isNull);
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
          {
            'selectorKind': 'STUDENT',
            'selectorCode': 'STD_EMMA',
            'selectorName': 'Emma Stone',
          },
          // Unhydrated row: null name stays empty for the client-side
          // fallback resolver.
          {
            'selectorKind': 'STUDENT',
            'selectorCode': 'STD_LIAM',
            'selectorName': null,
          },
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
      expect(model.recurrence, isNull);
      expect(model.students.map((s) => s.code), ['STD_EMMA', 'STD_LIAM']);
      expect(model.students.map((s) => s.name), ['Emma Stone', '']);
      expect(model.classrooms, isEmpty);

      final entity = model.toEntity();
      expect(entity.type, EventType.student);
      expect(entity.version, 0);
    });

    test('parses the recurrence rule from the rrule', () {
      final model = EventModel.fromApi({
        'code': 'EVT_1',
        'type': 'SCHOOL',
        'name': 'Weekly assembly',
        'seriesStartDate': '2026-09-07',
        'allDayFlag': true,
        'recurringFlag': true,
        'rrule': 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO;UNTIL=20261218T235959Z',
        'audiences': [
          {'selectorKind': 'SCHOOL_WIDE'},
        ],
      });

      expect(model.recurring, isTrue);
      final rule = model.recurrence!;
      expect(rule.frequency, RecurrenceFrequency.weekly);
      expect(rule.interval, 2);
      expect(rule.daysOfWeek, {DateTime.monday});
      expect(rule.endDate, DateTime(2026, 12, 18));
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

      expect(model.recurrence!.endDate, DateTime(2026, 11, 1));
    });
  });
}
