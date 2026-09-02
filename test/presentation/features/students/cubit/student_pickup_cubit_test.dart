import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/school_guardian_summary.dart';
import 'package:wowcare/domain/features/student/entities/student_pickup.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_pickup_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/delete_pickup_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardians_raw_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_pickups_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_pickup_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_pickup_cubit.dart';

StudentPickup _pickup(String code) => StudentPickup(
  code: code,
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phoneNumber: '5551234567',
  relation: 'FATHER',
  pickupType: 'CAREGIVER',
);

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetPickupsUseCase extends GetStudentPickupsUseCase {
  _FakeGetPickupsUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  List<StudentPickup> result = const <StudentPickup>[];
  Object? error;

  @override
  Future<List<StudentPickup>> call({
    required String studentCode,
    bool forceRefresh = false,
  }) async {
    calls++;
    studentCodes.add(studentCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeGuardiansRawUseCase extends GetGuardiansRawForSchoolUseCase {
  _FakeGuardiansRawUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> schoolCodes = <String>[];
  List<SchoolGuardianSummary> result = const <SchoolGuardianSummary>[];
  Object? error;

  @override
  Future<List<SchoolGuardianSummary>> call({
    required String schoolCode,
  }) async {
    calls++;
    schoolCodes.add(schoolCode);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeAddPickupUseCase extends AddPickupUseCase {
  _FakeAddPickupUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'added';

  @override
  Future<String> call({
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? relationshipDescription,
    required String pickupType,
    String? carpoolId,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

class _FakeUpdatePickupUseCase extends UpdatePickupUseCase {
  _FakeUpdatePickupUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  String result = 'updated';

  @override
  Future<String> call({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? clockPin,
    String? relationshipDescription,
    String? pickupType,
    String? carpoolId,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

class _FakeDeletePickupUseCase extends DeletePickupUseCase {
  _FakeDeletePickupUseCase() : super(_FakeRepo());

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
  final get = _FakeGetPickupsUseCase();
  final guardiansRaw = _FakeGuardiansRawUseCase();
  final add = _FakeAddPickupUseCase();
  final update = _FakeUpdatePickupUseCase();
  final delete = _FakeDeletePickupUseCase();

  StudentPickupCubit build() => StudentPickupCubit(
    getStudentPickupsUseCase: get,
    getGuardiansRawForSchoolUseCase: guardiansRaw,
    addPickupUseCase: add,
    updatePickupUseCase: update,
    deletePickupUseCase: delete,
  );
}

void main() {
  group('fetchPickups', () {
    test('returns the get use-case value', () async {
      final fakes = _Fakes();
      fakes.get.result = [_pickup('P1'), _pickup('P2')];
      final cubit = fakes.build();

      final pickups = await cubit.fetchPickups('S1');

      expect(fakes.get.calls, 1);
      expect(fakes.get.studentCodes.last, 'S1');
      expect(pickups.map((e) => e.code), ['P1', 'P2']);
      await cubit.close();
    });

    test('empty student code short-circuits to an empty list', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final pickups = await cubit.fetchPickups('');

      expect(fakes.get.calls, 0);
      expect(pickups, isEmpty);
      await cubit.close();
    });
  });

  group('fetchGuardiansRaw', () {
    test('returns the guardians-raw use-case value', () async {
      final fakes = _Fakes();
      fakes.guardiansRaw.result = const [
        SchoolGuardianSummary(
          code: 'G1',
          firstName: 'Ann',
          lastName: '',
          email: '',
          mobile: '',
        ),
      ];
      final cubit = fakes.build();

      final rows = await cubit.fetchGuardiansRaw('SCH');

      expect(fakes.guardiansRaw.calls, 1);
      expect(fakes.guardiansRaw.schoolCodes.last, 'SCH');
      expect(rows.first.code, 'G1');
      await cubit.close();
    });
  });

  group('mutations call the right use case', () {
    test('add', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.add(
        studentCode: 'S1',
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
        phoneNumber: '5551234567',
        relation: 'FATHER',
        pickupType: 'CAREGIVER',
      );

      expect(fakes.add.calls, 1);
      expect(message, 'added');
      await cubit.close();
    });

    test('update', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final message = await cubit.update(
        code: 'P1',
        studentCode: 'S1',
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
        phoneNumber: '5551234567',
        relation: 'FATHER',
        pickupType: 'CAREGIVER',
      );

      expect(fakes.update.calls, 1);
      expect(message, 'updated');
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
          studentCode: 'S1',
          firstName: 'A',
          lastName: 'B',
          email: 'a@b.com',
          phoneNumber: '5551234567',
          relation: 'FATHER',
          pickupType: 'CAREGIVER',
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
          relation: 'FATHER',
          pickupType: 'CAREGIVER',
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
}
