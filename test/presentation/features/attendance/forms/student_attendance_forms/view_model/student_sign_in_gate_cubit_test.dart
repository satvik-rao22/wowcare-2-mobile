import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_custom.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_sign_in_gate_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_sign_in_form.dart'
    show StudentEntity;

class _UnusedRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeStorage implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Fake sign-in form-list use case: returns a page built from a
/// studentCode -> isExpectedToday map.
class _FakeFormList extends GetStudentSignInFormListUseCase {
  _FakeFormList() : super(_UnusedRepo());

  Map<String, bool> expectedByCode = const {};
  bool throwOnCall = false;
  int calls = 0;

  @override
  Future<StudentAttendanceCustomPage> call({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    calls++;
    if (throwOnCall) throw Exception('network');
    final items = expectedByCode.entries
        .map(
          (e) => StudentAttendanceCustomItem(
            studentCode: e.key,
            studentName: e.key,
            isExpectedToday: e.value,
            classroomName: '',
            classroomCode: '',
            attendedDays: 0,
            attendedTime: '',
            attendedHours: 0,
            attendedMinutes: 0,
            tagCodes: const [],
            tagNames: const [],
          ),
        )
        .toList();
    return StudentAttendanceCustomPage(
      items: items,
      page: 0,
      size: size,
      totalPages: 1,
      totalElements: items.length,
      hasMore: false,
    );
  }
}

StudentEntity _student(String code, {bool expected = true}) => StudentEntity(
  id: code.hashCode,
  studentCode: code,
  fullName: 'Name $code',
  roomId: 1,
  roomName: 'Room',
  classroomCode: 'CLS',
  isExpectedToday: expected,
);

void main() {
  group('StudentSignInGateCubit', () {
    late _FakeFormList formList;
    late StudentSignInGateCubit cubit;

    setUp(() {
      formList = _FakeFormList();
      cubit = StudentSignInGateCubit(
        getStudentSignInFormList: formList,
        storageService: _FakeStorage(),
        apiClient: _FakeApiClient(),
      );
    });

    tearDown(() => cubit.close());

    test('seedStudents populates the working list', () {
      cubit.seedStudents([_student('S1'), _student('S2')]);
      expect(cubit.state.currentStudents.map((s) => s.studentCode), [
        'S1',
        'S2',
      ]);
    });

    test('setSelectedDate / setSelectedTime update state', () {
      final d = DateTime(2026, 8, 27);
      cubit.setSelectedDate(d);
      cubit.setSelectedTime(const TimeOfDay(hour: 9, minute: 30));
      expect(cubit.state.selectedDate, d);
      expect(cubit.state.selectedTime, const TimeOfDay(hour: 9, minute: 30));
    });

    test('acknowledgeUnexpected sets flag + comment', () {
      cubit.acknowledgeUnexpected('walk-in');
      expect(cubit.state.unexpectedSignInAcknowledged, isTrue);
      expect(cubit.state.notExpectedComment, 'walk-in');
    });

    test('removeStudent: returns true when list becomes empty', () {
      final s = _student('S1');
      cubit.seedStudents([s]);
      expect(cubit.removeStudent(s), isTrue);
      expect(cubit.state.currentStudents, isEmpty);
    });

    test('removeStudent: re-acknowledges when no unexpected remain', () {
      cubit.seedStudents([_student('S1'), _student('S2', expected: false)]);
      // S2 is unexpected -> not acknowledged yet.
      expect(cubit.hasUnexpectedAmongSelected(), isTrue);
      // Remove the unexpected one -> remaining are all expected -> re-acknowledge.
      final removed = cubit.removeStudent(_student('S2', expected: false));
      expect(removed, isFalse);
      expect(cubit.hasUnexpectedAmongSelected(), isFalse);
      expect(cubit.state.unexpectedSignInAcknowledged, isTrue);
      expect(cubit.state.notExpectedComment, '');
    });

    test(
      'hasUnexpected / names use expectedTodayFromApi over entity flag',
      () async {
        cubit.seedStudents([_student('S1', expected: true)]);
        // API says S1 is NOT expected today -> overrides the entity's true.
        formList.expectedByCode = {'S1': false};
        final outcome = await cubit.resolveExpectedToday();
        expect(outcome.superseded, isFalse);
        expect(outcome.needsDialog, isTrue);
        expect(outcome.unexpectedNames, ['Name S1']);
        expect(cubit.state.unexpectedGateLoading, isFalse);
        expect(cubit.state.unexpectedSignInAcknowledged, isFalse);
      },
    );

    test(
      'resolveExpectedToday: all expected -> no dialog, auto-acknowledged',
      () async {
        cubit.seedStudents([_student('S1')]);
        formList.expectedByCode = {'S1': true};
        final outcome = await cubit.resolveExpectedToday();
        expect(outcome.needsDialog, isFalse);
        expect(cubit.state.unexpectedSignInAcknowledged, isTrue);
        expect(cubit.state.unexpectedGateLoading, isFalse);
      },
    );

    test(
      'resolveExpectedToday: empty list -> acknowledged, no fetch',
      () async {
        final outcome = await cubit.resolveExpectedToday();
        expect(outcome.needsDialog, isFalse);
        expect(formList.calls, 0);
        expect(cubit.state.unexpectedSignInAcknowledged, isTrue);
        expect(cubit.state.unexpectedGateLoading, isFalse);
      },
    );

    test(
      'resolveExpectedToday: fetch error clears map but still gates',
      () async {
        cubit.seedStudents([_student('S1', expected: false)]);
        formList.throwOnCall = true;
        final outcome = await cubit.resolveExpectedToday();
        expect(cubit.state.expectedTodayFromApi, isEmpty);
        // entity flag (false) makes S1 unexpected -> dialog.
        expect(outcome.needsDialog, isTrue);
      },
    );
  });
}
