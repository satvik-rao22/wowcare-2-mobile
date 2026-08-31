import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';
import 'package:wowcare/domain/features/staff/entities/staff_schedule_entry.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_school_regular_schedules_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_staff_schedules_usecase.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_schedule_cubit.dart';

SchoolRegularScheduleDay _day(String dayOfWeek) => SchoolRegularScheduleDay(
  dayOfWeek: dayOfWeek,
  startTime: '08:00:00',
  endTime: '17:00:00',
  status: 'ACTIVE',
  type: 'REGULAR',
);

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetUseCase extends GetSchoolRegularSchedulesUseCase {
  _FakeGetUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> schoolCodes = <String>[];
  List<SchoolRegularScheduleDay> result = const <SchoolRegularScheduleDay>[];
  Object? error;

  @override
  Future<List<SchoolRegularScheduleDay>> call({
    required String schoolCode,
  }) async {
    calls++;
    schoolCodes.add(schoolCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeUpdateUseCase extends UpdateStaffSchedulesUseCase {
  _FakeUpdateUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> staffCodes = <String>[];
  Object? error;
  String result = 'saved';
  Completer<String>? gate;

  @override
  Future<String> call({
    required String staffCode,
    required List<StaffWorkScheduleEntry> workSchedules,
    required List<StaffBreakScheduleEntry> breakSchedules,
  }) {
    calls++;
    staffCodes.add(staffCode);
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _Fakes {
  final get = _FakeGetUseCase();
  final update = _FakeUpdateUseCase();

  StaffScheduleCubit build() => StaffScheduleCubit(
    getSchoolRegularSchedulesUseCase: get,
    updateStaffSchedulesUseCase: update,
  );
}

void main() {
  group('fetchSchoolRegularSchedules', () {
    test('returns the value from the get use case', () async {
      final fakes = _Fakes();
      fakes.get.result = [_day('MONDAY'), _day('TUESDAY')];
      final cubit = fakes.build();

      final days = await cubit.fetchSchoolRegularSchedules('SCH');

      expect(fakes.get.calls, 1);
      expect(fakes.get.schoolCodes.last, 'SCH');
      expect(days.map((e) => e.dayOfWeek), ['MONDAY', 'TUESDAY']);
      await cubit.close();
    });

    test('propagates errors from the get use case', () async {
      final fakes = _Fakes();
      fakes.get.error = Exception('boom');
      final cubit = fakes.build();

      await expectLater(
        cubit.fetchSchoolRegularSchedules('SCH'),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  group('updateSchedules', () {
    test('calls the update use case and returns its message', () async {
      final fakes = _Fakes();
      fakes.update.result = 'schedule saved';
      final cubit = fakes.build();

      final message = await cubit.updateSchedules(
        staffCode: 'ST1',
        workSchedules: const [
          StaffWorkScheduleEntry(
            dayOfWeek: 'MONDAY',
            workStartTime: '09:00:00',
            workEndTime: '17:00:00',
          ),
        ],
        breakSchedules: const [],
      );

      expect(fakes.update.calls, 1);
      expect(fakes.update.staffCodes.last, 'ST1');
      expect(message, 'schedule saved');
      await cubit.close();
    });

    test('rethrows on error', () async {
      final fakes = _Fakes();
      fakes.update.error = Exception('update failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateSchedules(
          staffCode: 'ST1',
          workSchedules: const [],
          breakSchedules: const [],
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  test(
    'single-flight: two concurrent updateSchedules for the same staffCode '
    'issue ONE use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<String>();
      fakes.update.gate = gate;
      final cubit = fakes.build();

      final f1 = cubit.updateSchedules(
        staffCode: 'ST1',
        workSchedules: const [],
        breakSchedules: const [],
      );
      final f2 = cubit.updateSchedules(
        staffCode: 'ST1',
        workSchedules: const [],
        breakSchedules: const [],
      );

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.update.calls, 1);

      gate.complete('saved');
      await Future.wait<String>([f1, f2]);

      expect(fakes.update.calls, 1);
      await cubit.close();
    },
  );
}
