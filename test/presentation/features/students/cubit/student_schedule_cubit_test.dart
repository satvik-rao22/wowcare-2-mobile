import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_school_regular_schedules_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_schedule_cubit.dart';

class _FakeRepo implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeUseCase extends GetSchoolRegularSchedulesUseCase {
  _FakeUseCase() : super(_FakeRepo());

  List<SchoolRegularScheduleDay> result = const [];
  Object? error;

  @override
  Future<List<SchoolRegularScheduleDay>> call({required String schoolCode}) async {
    if (error != null) throw error!;
    return result;
  }
}

SchoolRegularScheduleDay _day(
  String dow, {
  String start = '07:00:00',
  String end = '18:00:00',
  String? status,
  String? type,
}) =>
    SchoolRegularScheduleDay(
      dayOfWeek: dow,
      startTime: start,
      endTime: end,
      status: status,
      type: type,
    );

void main() {
  late _FakeUseCase useCase;
  StudentScheduleCubit build() =>
      StudentScheduleCubit(getSchoolRegularSchedulesUseCase: useCase);

  setUp(() => useCase = _FakeUseCase());

  const t9 = TimeOfDay(hour: 9, minute: 0);
  const t16 = TimeOfDay(hour: 16, minute: 0);

  group('initialize', () {
    test('empty when no initial schedule', () {
      final cubit = build()..initialize(null);
      expect(cubit.state.schedule, isEmpty);
      expect(cubit.state.hasInitialSchedule, isFalse);
    });

    test('deep-copies an initial schedule', () {
      final initial = {
        'Monday': {'start': t9, 'end': t16},
      };
      final cubit = build()..initialize(initial);
      expect(cubit.state.hasInitialSchedule, isTrue);
      expect(cubit.state.schedule['Monday']?['start'], t9);
      // mutating the source must not affect cubit state
      initial['Monday']!['start'] = const TimeOfDay(hour: 1, minute: 0);
      expect(cubit.state.schedule['Monday']?['start'], t9);
    });
  });

  group('loadSchoolSchedules', () {
    test('keeps regular/active days and fills defaults (no initial)', () async {
      useCase.result = [_day('MONDAY'), _day('TUESDAY')];
      final cubit = build()..initialize(null);

      final removed = await cubit.loadSchoolSchedules('SCH');

      expect(removed, isEmpty);
      expect(cubit.workingDays, ['Monday', 'Tuesday']);
      // defaults filled from the 07:00–18:00 bounds
      expect(cubit.state.schedule['Monday']?['start'],
          const TimeOfDay(hour: 7, minute: 0));
      expect(cubit.state.schedule['Monday']?['end'],
          const TimeOfDay(hour: 18, minute: 0));
    });

    test('excludes inactive + non-regular days', () async {
      useCase.result = [
        _day('MONDAY'),
        _day('TUESDAY', status: 'INACTIVE'),
        _day('WEDNESDAY', type: 'HOLIDAY'),
      ];
      final cubit = build()..initialize(null);
      await cubit.loadSchoolSchedules('SCH');
      expect(cubit.workingDays, ['Monday']);
    });

    test('prunes a scheduled entry on a now-closed day and reports it',
        () async {
      useCase.result = [_day('MONDAY')];
      final cubit = build()
        ..initialize({
          'Monday': {'start': t9, 'end': t16},
          'Sunday': {'start': t9, 'end': t16},
        });

      final removed = await cubit.loadSchoolSchedules('SCH');

      expect(removed, ['Sunday']);
      expect(cubit.state.schedule.containsKey('Sunday'), isFalse);
      expect(cubit.state.schedule.containsKey('Monday'), isTrue);
    });

    test('API error is non-fatal (no removed days)', () async {
      useCase.error = Exception('down');
      final cubit = build()..initialize(null);
      final removed = await cubit.loadSchoolSchedules('SCH');
      expect(removed, isEmpty);
    });
  });

  group('applyPickedTime', () {
    Future<StudentScheduleCubit> loaded() async {
      useCase.result = [_day('MONDAY'), _day('TUESDAY')];
      final cubit = build()..initialize(null);
      await cubit.loadSchoolSchedules('SCH');
      return cubit;
    }

    test('valid time updates the day and returns null', () async {
      final cubit = await loaded();
      final err = cubit.applyPickedTime('Monday', 'start', t9);
      expect(err, isNull);
      expect(cubit.state.schedule['Monday']?['start'], t9);
    });

    test('out-of-hours time returns an error and does not change state',
        () async {
      final cubit = await loaded();
      final before = cubit.state.schedule['Monday']?['start'];
      final err = cubit.applyPickedTime(
        'Monday',
        'start',
        const TimeOfDay(hour: 5, minute: 0),
      );
      expect(err, isNotNull);
      expect(cubit.state.schedule['Monday']?['start'], before);
    });

    test('copyToAllDays applies the change to every working day', () async {
      final cubit = await loaded();
      cubit.setCopyToAllDays(true);
      cubit.applyPickedTime('Monday', 'start', t9);
      cubit.applyPickedTime('Monday', 'end', t16);
      expect(cubit.state.schedule['Tuesday']?['start'], t9);
      expect(cubit.state.schedule['Tuesday']?['end'], t16);
    });
  });

  group('day enable/remove + submit validation', () {
    Future<StudentScheduleCubit> loaded() async {
      useCase.result = [_day('MONDAY')];
      final cubit = build()..initialize(null);
      await cubit.loadSchoolSchedules('SCH');
      return cubit;
    }

    test('removeDay drops the day; enableDay restores defaults', () async {
      final cubit = await loaded();
      cubit.removeDay('Monday');
      expect(cubit.state.schedule.containsKey('Monday'), isFalse);
      cubit.enableDay('Monday');
      expect(cubit.state.schedule['Monday']?['start'],
          const TimeOfDay(hour: 7, minute: 0));
    });

    test('validateForSubmit: empty schedule errors', () async {
      final cubit = build()..initialize(null);
      expect(cubit.validateForSubmit(), isNotNull);
    });

    test('validateForSubmit: a well-formed schedule passes', () async {
      final cubit = await loaded();
      expect(cubit.validateForSubmit(), isNull);
    });
  });
}
