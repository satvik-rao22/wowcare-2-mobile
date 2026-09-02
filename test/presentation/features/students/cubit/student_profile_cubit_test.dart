import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_health.dart';
import 'package:wowcare/domain/features/student/entities/student_settings.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_health_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_settings_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_regular_schedules_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_profile_cubit.dart';

StudentHealth _health({String? allergy}) => StudentHealth(
  allergy: allergy ?? 'peanuts',
  medications: 'none',
  dietRestrictions: 'none',
  photoPermission: true,
);

StudentSettings _settings({bool canParentEdit = true}) => StudentSettings(
  code: 'SET1',
  schoolCode: 'SCH1',
  organizationCode: 'ORG1',
  canParentEditChildHealthRecords: canParentEdit,
);

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetSettingsUseCase extends GetStudentSettingsUseCase {
  _FakeGetSettingsUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> schoolCodes = <String>[];
  StudentSettings result = _settings();
  Object? error;

  @override
  Future<StudentSettings> call({required String schoolCode}) async {
    calls++;
    schoolCodes.add(schoolCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeGetHealthUseCase extends GetStudentHealthUseCase {
  _FakeGetHealthUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  StudentHealth result = _health();
  Object? error;

  @override
  Future<StudentHealth> call({required String studentCode}) async {
    calls++;
    studentCodes.add(studentCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeUpdateSchedulesUseCase extends UpdateStudentRegularSchedulesUseCase {
  _FakeUpdateSchedulesUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  final List<List<Map<String, dynamic>>> schedules =
      <List<Map<String, dynamic>>>[];
  Object? error;
  String result = 'Schedule updated';
  Completer<String>? gate;

  @override
  Future<String> call({
    required String schoolCode,
    required String studentCode,
    required List<Map<String, dynamic>> schedule,
  }) {
    calls++;
    studentCodes.add(studentCode);
    schedules.add(schedule);
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _Fakes {
  final getSettings = _FakeGetSettingsUseCase();
  final getHealth = _FakeGetHealthUseCase();
  final updateSchedules = _FakeUpdateSchedulesUseCase();

  StudentProfileCubit build() => StudentProfileCubit(
    getStudentSettingsUseCase: getSettings,
    getStudentHealthUseCase: getHealth,
    updateStudentRegularSchedulesUseCase: updateSchedules,
  );
}

void main() {
  group('reads', () {
    test('fetchSettings returns the get use case value', () async {
      final fakes = _Fakes();
      fakes.getSettings.result = _settings(canParentEdit: false);
      final cubit = fakes.build();

      final result = await cubit.fetchSettings('SCH1');

      expect(fakes.getSettings.calls, 1);
      expect(fakes.getSettings.schoolCodes.last, 'SCH1');
      expect(result.canParentEditChildHealthRecords, isFalse);
      await cubit.close();
    });

    test('fetchHealth returns the get use case value', () async {
      final fakes = _Fakes();
      fakes.getHealth.result = _health(allergy: 'shellfish');
      final cubit = fakes.build();

      final result = await cubit.fetchHealth('S1');

      expect(fakes.getHealth.calls, 1);
      expect(fakes.getHealth.studentCodes.last, 'S1');
      expect(result.allergy, 'shellfish');
      await cubit.close();
    });
  });

  group('mutations call the right use case', () {
    test('updateRegularSchedules', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final schedule = [
        {'dayOfWeek': 'MONDAY', 'startTime': '09:00'},
      ];
      final result = await cubit.updateRegularSchedules(
        schoolCode: 'SCH1',
        studentCode: 'S1',
        schedule: schedule,
      );

      expect(fakes.updateSchedules.calls, 1);
      expect(fakes.updateSchedules.studentCodes.last, 'S1');
      expect(fakes.updateSchedules.schedules.last, schedule);
      expect(result, 'Schedule updated');
      await cubit.close();
    });
  });

  group('mutations rethrow on error', () {
    test('updateRegularSchedules rethrows', () async {
      final fakes = _Fakes();
      fakes.updateSchedules.error = Exception('update failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateRegularSchedules(
          schoolCode: 'SCH1',
          studentCode: 'S1',
          schedule: const [],
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  test(
    'single-flight: two concurrent updateRegularSchedules for the same student '
    'issue ONE use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<String>();
      fakes.updateSchedules.gate = gate;
      final cubit = fakes.build();

      final f1 = cubit.updateRegularSchedules(
        schoolCode: 'SCH1',
        studentCode: 'S1',
        schedule: const [],
      );
      final f2 = cubit.updateRegularSchedules(
        schoolCode: 'SCH1',
        studentCode: 'S1',
        schedule: const [],
      );

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.updateSchedules.calls, 1);

      gate.complete('done');
      await Future.wait<String>([f1, f2]);

      expect(fakes.updateSchedules.calls, 1);
      await cubit.close();
    },
  );
}
