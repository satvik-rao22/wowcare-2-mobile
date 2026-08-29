import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_guardian.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/delete_guardian_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_guardians_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_guardian_cubit.dart';

StudentGuardian _guardian(String code) => StudentGuardian(
  guardianCode: code,
  userCode: 'U-$code',
  firstName: 'Ann',
  lastName: 'Doe',
  mobile: '5551234567',
  email: 'ann@example.com',
  relationToStudent: 'Mother',
  primaryContact: true,
  legalCustody: true,
);

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetGuardiansUseCase extends GetStudentGuardiansUseCase {
  _FakeGetGuardiansUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  List<StudentGuardian> result = const <StudentGuardian>[];
  Object? error;

  @override
  Future<List<StudentGuardian>> call({
    required String studentCode,
    bool forceRefresh = false,
  }) async {
    calls++;
    studentCodes.add(studentCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeDeleteGuardianUseCase extends DeleteGuardianUseCase {
  _FakeDeleteGuardianUseCase() : super(_FakeRepo());

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
  final get = _FakeGetGuardiansUseCase();
  final delete = _FakeDeleteGuardianUseCase();

  StudentGuardianCubit build() => StudentGuardianCubit(
    getStudentGuardiansUseCase: get,
    deleteGuardianUseCase: delete,
  );
}

void main() {
  group('fetchGuardians', () {
    test('returns the get use-case value', () async {
      final fakes = _Fakes();
      fakes.get.result = [_guardian('G1'), _guardian('G2')];
      final cubit = fakes.build();

      final guardians = await cubit.fetchGuardians('S1');

      expect(fakes.get.calls, 1);
      expect(fakes.get.studentCodes.last, 'S1');
      expect(guardians.map((e) => e.guardianCode), ['G1', 'G2']);
      await cubit.close();
    });

    test('empty student code short-circuits to an empty list', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final guardians = await cubit.fetchGuardians('');

      expect(fakes.get.calls, 0);
      expect(guardians, isEmpty);
      await cubit.close();
    });
  });

  group('delete', () {
    test('calls the delete use case', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.delete(code: 'G1', studentCode: 'S1');

      expect(fakes.delete.calls, 1);
      expect(message, 'deleted');
      await cubit.close();
    });

    test('rethrows on error', () async {
      final fakes = _Fakes();
      fakes.delete.error = Exception('delete failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.delete(code: 'G1', studentCode: 'S1'),
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

      final f1 = cubit.delete(code: 'G1', studentCode: 'S1');
      final f2 = cubit.delete(code: 'G1', studentCode: 'S1');

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.delete.calls, 1);

      gate.complete('deleted');
      await Future.wait<String>([f1, f2]);

      expect(fakes.delete.calls, 1);
      await cubit.close();
    },
  );
}
