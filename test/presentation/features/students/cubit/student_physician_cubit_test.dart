import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_physician.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_physician_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/delete_physician_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_physicians_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_physician_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_physician_cubit.dart';

StudentPhysician _physician(String code) => StudentPhysician(
  code: code,
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phoneNumber: '5551234567',
  address: '1 Main St',
  specialty: '',
  notes: '',
  status: 'ACTIVE',
);

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetUseCase extends GetStudentPhysiciansUseCase {
  _FakeGetUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  List<StudentPhysician> result = const <StudentPhysician>[];
  Object? error;

  @override
  Future<List<StudentPhysician>> call({required String studentCode, bool forceRefresh = false}) async {
    calls++;
    studentCodes.add(studentCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeAddUseCase extends AddPhysicianUseCase {
  _FakeAddUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  StudentPhysician result = _physician('P-NEW');
  Completer<StudentPhysician>? gate;

  @override
  Future<StudentPhysician> call({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) async {
    calls++;
    if (error != null) throw error!;
    if (gate != null) return gate!.future;
    return result;
  }
}

class _FakeUpdateUseCase extends UpdatePhysicianUseCase {
  _FakeUpdateUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  StudentPhysician result = _physician('P1');

  @override
  Future<StudentPhysician> call({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

class _FakeDeleteUseCase extends DeletePhysicianUseCase {
  _FakeDeleteUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'deleted';
  Completer<String>? gate;

  @override
  Future<String> call({required String code, required String studentCode}) {
    calls++;
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _Fakes {
  final get = _FakeGetUseCase();
  final add = _FakeAddUseCase();
  final update = _FakeUpdateUseCase();
  final delete = _FakeDeleteUseCase();

  StudentPhysicianCubit build() => StudentPhysicianCubit(
    getStudentPhysiciansUseCase: get,
    addPhysicianUseCase: add,
    updatePhysicianUseCase: update,
    deletePhysicianUseCase: delete,
  );
}

void main() {
  group('load', () {
    test('populates physicians from the get use case', () async {
      final fakes = _Fakes();
      fakes.get.result = [_physician('P1'), _physician('P2')];
      final cubit = fakes.build();

      await cubit.load('S1');

      expect(fakes.get.calls, 1);
      expect(fakes.get.studentCodes.last, 'S1');
      expect(cubit.state.physicians.map((e) => e.code), ['P1', 'P2']);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNull);
      await cubit.close();
    });

    test('empty student code short-circuits to an empty list', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      await cubit.load('');

      expect(fakes.get.calls, 0);
      expect(cubit.state.physicians, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      await cubit.close();
    });

    test('sets errorMessage on failure', () async {
      final fakes = _Fakes();
      fakes.get.error = Exception('boom');
      final cubit = fakes.build();

      await cubit.load('S1');

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
      await cubit.close();
    });
  });

  group('mutations call the right use case', () {
    test('add', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final result = await cubit.add(
        schoolCode: 'SCH',
        studentCode: 'S1',
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
        phoneNumber: '5551234567',
        address: 'addr',
      );

      expect(fakes.add.calls, 1);
      expect(result.code, 'P-NEW');
      await cubit.close();
    });

    test('update', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      await cubit.update(
        code: 'P1',
        studentCode: 'S1',
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
        phoneNumber: '5551234567',
        address: 'addr',
      );

      expect(fakes.update.calls, 1);
      await cubit.close();
    });

    test('delete', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.delete(code: 'P1', studentCode: 'S1');

      expect(fakes.delete.calls, 1);
      expect(message, 'deleted');
      await cubit.close();
    });
  });

  group('mutations rethrow on error', () {
    test('add rethrows', () async {
      final fakes = _Fakes();
      fakes.add.error = Exception('add failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.add(
          schoolCode: 'SCH',
          studentCode: 'S1',
          firstName: 'A',
          lastName: 'B',
          email: 'a@b.com',
          phoneNumber: '5551234567',
          address: 'addr',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('update rethrows', () async {
      final fakes = _Fakes();
      fakes.update.error = Exception('update failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.update(
          code: 'P1',
          studentCode: 'S1',
          firstName: 'A',
          lastName: 'B',
          email: 'a@b.com',
          phoneNumber: '5551234567',
          address: 'addr',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('delete rethrows', () async {
      final fakes = _Fakes();
      fakes.delete.error = Exception('delete failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.delete(code: 'P1', studentCode: 'S1'),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  test(
    'single-flight: two concurrent delete() for the same code issue ONE '
    'use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<String>();
      fakes.delete.gate = gate;
      final cubit = fakes.build();

      final f1 = cubit.delete(code: 'P1', studentCode: 'S1');
      final f2 = cubit.delete(code: 'P1', studentCode: 'S1');

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.delete.calls, 1);

      gate.complete('deleted');
      await Future.wait<String>([f1, f2]);

      expect(fakes.delete.calls, 1);
      await cubit.close();
    },
  );

  test(
    'add flips mutationInProgress true while in-flight, false on completion '
    '(drives the form Save button)',
    () async {
      final fakes = _Fakes();
      final gate = Completer<StudentPhysician>();
      fakes.add.gate = gate;
      final cubit = fakes.build();

      expect(cubit.state.mutationInProgress, isFalse);

      final future = cubit.add(
        schoolCode: 'SC',
        studentCode: 'S1',
        firstName: 'A',
        lastName: 'B',
        email: '',
        phoneNumber: '1234567890',
        address: '',
      );

      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.mutationInProgress, isTrue);

      gate.complete(_physician('P-NEW'));
      await future;
      expect(cubit.state.mutationInProgress, isFalse);
      await cubit.close();
    },
  );

  test('delete success triggers a reload (get use case called again)', () async {
    final fakes = _Fakes();
    final cubit = fakes.build();

    // Prime with an explicit load so we can prove delete adds another get call.
    await cubit.load('S1');
    expect(fakes.get.calls, 1);

    await cubit.delete(code: 'P1', studentCode: 'S1');

    expect(fakes.delete.calls, 1);
    expect(fakes.get.calls, 2);
    expect(fakes.get.studentCodes.last, 'S1');
    await cubit.close();
  });
}
