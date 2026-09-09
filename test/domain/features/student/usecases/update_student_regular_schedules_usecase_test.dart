import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_regular_schedule_input.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_regular_schedules_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> updateStudentRegularSchedules({
    required String schoolCode,
    required String studentCode,
    required List<StudentRegularScheduleInput> schedule,
  }) async {
    calls.add({
      'schoolCode': schoolCode,
      'studentCode': studentCode,
      'schedule': schedule,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const schedule = [
    StudentRegularScheduleInput(
      dayOfWeek: 'MONDAY',
      startTime: '08:00:00',
      halfDay: '12:00:00',
      endTime: '17:00:00',
    ),
  ];

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = 'updated';
    final useCase = UpdateStudentRegularSchedulesUseCase(repo);
    final r = await useCase(
      schoolCode: 'SCH1',
      studentCode: 'S1',
      schedule: schedule,
    );
    expect(r, 'updated');
    expect(repo.calls.single['schoolCode'], 'SCH1');
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['schedule'], same(schedule));
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentRegularSchedulesUseCase(repo);
    expect(
      () => useCase(schoolCode: 'SCH1', studentCode: 'S1', schedule: schedule),
      throwsA(isA<Exception>()),
    );
  });
}
