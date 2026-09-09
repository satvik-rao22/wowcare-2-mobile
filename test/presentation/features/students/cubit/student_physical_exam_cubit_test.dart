import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_physical_exam.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_physical_exam_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_physical_exams_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_physical_exam_usecase.dart';
import 'package:wowcare/presentation/features/students/view_model/student_physical_exam_cubit.dart';

StudentPhysicalExam _exam(String code, {String? status}) => StudentPhysicalExam(
  code: code,
  examDate: '2026-01-01',
  status: status ?? 'DUE',
);

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetExamsUseCase extends GetStudentPhysicalExamsUseCase {
  _FakeGetExamsUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  final List<bool> forceRefreshes = <bool>[];
  List<StudentPhysicalExam> result = const <StudentPhysicalExam>[];
  Object? error;

  @override
  Future<List<StudentPhysicalExam>> call({
    required String studentCode,
    bool forceRefresh = false,
  }) async {
    calls++;
    studentCodes.add(studentCode);
    forceRefreshes.add(forceRefresh);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeAddExamUseCase extends AddStudentPhysicalExamUseCase {
  _FakeAddExamUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  Object? error;
  StudentPhysicalExam result = _exam('E1');
  Completer<StudentPhysicalExam>? gate;

  @override
  Future<StudentPhysicalExam> call({
    required String studentCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) {
    calls++;
    studentCodes.add(studentCode);
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _FakeUpdateExamUseCase extends UpdateStudentPhysicalExamUseCase {
  _FakeUpdateExamUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> examCodes = <String>[];
  Object? error;
  StudentPhysicalExam result = _exam('E1', status: 'COMPLETED');
  Completer<StudentPhysicalExam>? gate;

  @override
  Future<StudentPhysicalExam> call({
    required String studentCode,
    required String examCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) {
    calls++;
    examCodes.add(examCode);
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _Fakes {
  final getExams = _FakeGetExamsUseCase();
  final addExam = _FakeAddExamUseCase();
  final updateExam = _FakeUpdateExamUseCase();

  StudentPhysicalExamCubit build() => StudentPhysicalExamCubit(
    getStudentPhysicalExamsUseCase: getExams,
    addStudentPhysicalExamUseCase: addExam,
    updateStudentPhysicalExamUseCase: updateExam,
  );
}

void main() {
  group('reads', () {
    test('fetchPhysicalExams returns the get use case value', () async {
      final fakes = _Fakes();
      fakes.getExams.result = [_exam('E1'), _exam('E2')];
      final cubit = fakes.build();

      final result = await cubit.fetchPhysicalExams('S1', forceRefresh: true);

      expect(fakes.getExams.calls, 1);
      expect(fakes.getExams.studentCodes.last, 'S1');
      expect(fakes.getExams.forceRefreshes.last, isTrue);
      expect(result.map((e) => e.code), ['E1', 'E2']);
      await cubit.close();
    });

    test('fetchPhysicalExams defaults forceRefresh to false', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      await cubit.fetchPhysicalExams('S1');

      expect(fakes.getExams.forceRefreshes.last, isFalse);
      await cubit.close();
    });
  });

  group('mutations call the right use case', () {
    test('add', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final result = await cubit.add(
        studentCode: 'S1',
        examDate: DateTime(2026, 1, 1),
        status: 'DUE',
      );

      expect(fakes.addExam.calls, 1);
      expect(fakes.addExam.studentCodes.last, 'S1');
      expect(fakes.updateExam.calls, 0);
      expect(result.code, 'E1');
      await cubit.close();
    });

    test('update', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final result = await cubit.update(
        studentCode: 'S1',
        examCode: 'E1',
        examDate: DateTime(2026, 1, 1),
        status: 'COMPLETED',
      );

      expect(fakes.updateExam.calls, 1);
      expect(fakes.updateExam.examCodes.last, 'E1');
      expect(fakes.addExam.calls, 0);
      expect(result.status, 'COMPLETED');
      await cubit.close();
    });
  });

  group('mutations rethrow on error', () {
    test('add rethrows', () async {
      final fakes = _Fakes();
      fakes.addExam.error = Exception('add failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.add(
          studentCode: 'S1',
          examDate: DateTime(2026, 1, 1),
          status: 'DUE',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('update rethrows', () async {
      final fakes = _Fakes();
      fakes.updateExam.error = Exception('update failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.update(
          studentCode: 'S1',
          examCode: 'E1',
          examDate: DateTime(2026, 1, 1),
          status: 'COMPLETED',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  test(
    'single-flight: two concurrent update() for the same examCode issue '
    'ONE use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<StudentPhysicalExam>();
      fakes.updateExam.gate = gate;
      final cubit = fakes.build();

      final f1 = cubit.update(
        studentCode: 'S1',
        examCode: 'E1',
        examDate: DateTime(2026, 1, 1),
        status: 'COMPLETED',
      );
      final f2 = cubit.update(
        studentCode: 'S1',
        examCode: 'E1',
        examDate: DateTime(2026, 1, 1),
        status: 'COMPLETED',
      );

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.updateExam.calls, 1);

      gate.complete(_exam('E1', status: 'COMPLETED'));
      await Future.wait<StudentPhysicalExam>([f1, f2]);

      expect(fakes.updateExam.calls, 1);
      await cubit.close();
    },
  );

  test(
    'add flips mutationInProgress true while in-flight, false on completion '
    '(drives the add-exam Save button)',
    () async {
      final fakes = _Fakes();
      final gate = Completer<StudentPhysicalExam>();
      fakes.addExam.gate = gate;
      final cubit = fakes.build();

      expect(cubit.state.mutationInProgress, isFalse);

      final future = cubit.add(
        studentCode: 'S1',
        examDate: DateTime(2026, 1, 1),
        status: 'COMPLETED',
      );

      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.mutationInProgress, isTrue);

      gate.complete(_exam('E1', status: 'COMPLETED'));
      await future;
      expect(cubit.state.mutationInProgress, isFalse);
      await cubit.close();
    },
  );

  group('add-exam form model', () {
    final date = DateTime(2026, 3, 10);

    test('initial form fields are null', () {
      final cubit = _Fakes().build();
      expect(cubit.state.formExamDate, isNull);
      expect(cubit.state.formStatus, isNull);
    });

    test('initializeForm seeds date + status', () {
      final cubit = _Fakes().build()
        ..initializeForm(examDate: date, status: 'Completed');
      expect(cubit.state.formExamDate, date);
      expect(cubit.state.formStatus, 'Completed');
    });

    test('initializeForm can seed nulls', () {
      final cubit = _Fakes().build()
        ..initializeForm(examDate: date, status: 'Completed')
        ..initializeForm(examDate: null, status: null);
      expect(cubit.state.formExamDate, isNull);
      expect(cubit.state.formStatus, isNull);
    });

    test('setFormExamDate updates only the date', () {
      final cubit = _Fakes().build()
        ..initializeForm(examDate: null, status: 'Completed');
      cubit.setFormExamDate(date);
      expect(cubit.state.formExamDate, date);
      expect(cubit.state.formStatus, 'Completed');
    });

    test('setFormStatus updates only the status', () {
      final cubit = _Fakes().build()
        ..initializeForm(examDate: date, status: null);
      cubit.setFormStatus('Completed');
      expect(cubit.state.formStatus, 'Completed');
      expect(cubit.state.formExamDate, date);
    });
  });
}
