import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_health.dart';
import 'package:wowcare/domain/features/student/entities/student_health_update_request.dart';
import 'package:wowcare/domain/features/student/entities/student_immunization.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_health_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_immunizations_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_health_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_immunization_record_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_health_cubit.dart';

StudentHealth _health({String? allergy}) => StudentHealth(
  allergy: allergy ?? 'peanuts',
  medications: 'none',
  dietRestrictions: 'none',
  photoPermission: true,
);

StudentHealthUpdateRequest _request({String allergy = 'peanuts'}) =>
    StudentHealthUpdateRequest(
      allergy: allergy,
      medications: 'none',
      dietRestrictions: 'none',
      photoPermission: true,
    );

StudentImmunization _immunization(String code) => StudentImmunization(
  code: code,
  studentCode: 'S1',
  vaccineName: 'MMR',
  vaccineDoseCode: 'VDC1',
  doseNumber: 1,
  status: 'DUE',
);

/// Repository that fails loudly — the use-case fakes never touch it.
class _FakeRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
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

class _FakeUpdateHealthUseCase extends UpdateStudentHealthUseCase {
  _FakeUpdateHealthUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<StudentHealthUpdateRequest> requests =
      <StudentHealthUpdateRequest>[];
  Object? error;
  StudentHealth result = _health(allergy: 'updated');
  Completer<StudentHealth>? gate;

  @override
  Future<StudentHealth> call({
    required String studentCode,
    required StudentHealthUpdateRequest request,
  }) {
    calls++;
    requests.add(request);
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _FakeGetImmunizationsUseCase extends GetStudentImmunizationsUseCase {
  _FakeGetImmunizationsUseCase() : super(_FakeRepo());

  int calls = 0;
  final List<String> studentCodes = <String>[];
  final List<bool> forceRefreshes = <bool>[];
  List<StudentImmunization> result = const <StudentImmunization>[];
  Object? error;

  @override
  Future<List<StudentImmunization>> call({
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

class _FakeUpdateImmunizationUseCase
    extends UpdateStudentImmunizationRecordUseCase {
  _FakeUpdateImmunizationUseCase() : super(_FakeRepo());

  int calls = 0;
  Object? error;
  StudentImmunization result = _immunization('I1');
  Completer<StudentImmunization>? gate;

  @override
  Future<StudentImmunization> call({
    required String studentCode,
    required StudentImmunization record,
    required DateTime date,
    required String status,
    String? exemptionReason,
  }) {
    calls++;
    if (error != null) return Future.error(error!);
    if (gate != null) return gate!.future;
    return Future.value(result);
  }
}

class _Fakes {
  final getHealth = _FakeGetHealthUseCase();
  final updateHealth = _FakeUpdateHealthUseCase();
  final getImmunizations = _FakeGetImmunizationsUseCase();
  final updateImmunization = _FakeUpdateImmunizationUseCase();

  StudentHealthCubit build() => StudentHealthCubit(
    getStudentHealthUseCase: getHealth,
    updateStudentHealthUseCase: updateHealth,
    getStudentImmunizationsUseCase: getImmunizations,
    updateStudentImmunizationRecordUseCase: updateImmunization,
  );
}

void main() {
  group('reads', () {
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

    test('fetchImmunizations returns the get use case value', () async {
      final fakes = _Fakes();
      fakes.getImmunizations.result = [
        _immunization('I1'),
        _immunization('I2'),
      ];
      final cubit = fakes.build();

      final result = await cubit.fetchImmunizations('S1', forceRefresh: true);

      expect(fakes.getImmunizations.calls, 1);
      expect(fakes.getImmunizations.studentCodes.last, 'S1');
      expect(fakes.getImmunizations.forceRefreshes.last, isTrue);
      expect(result.map((e) => e.code), ['I1', 'I2']);
      await cubit.close();
    });

    test('fetchImmunizations defaults forceRefresh to false', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      await cubit.fetchImmunizations('S1');

      expect(fakes.getImmunizations.forceRefreshes.last, isFalse);
      await cubit.close();
    });
  });

  group('mutations call the right use case', () {
    test('updateHealth', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final request = _request();
      final result = await cubit.updateHealth(
        studentCode: 'S1',
        request: request,
      );

      expect(fakes.updateHealth.calls, 1);
      expect(fakes.updateHealth.requests.last, request);
      expect(result.allergy, 'updated');
      await cubit.close();
    });

    test('updateImmunization', () async {
      final fakes = _Fakes();
      final cubit = fakes.build();

      final result = await cubit.updateImmunization(
        studentCode: 'S1',
        record: _immunization('I1'),
        date: DateTime(2026, 1, 1),
        status: 'COMPLETED',
      );

      expect(fakes.updateImmunization.calls, 1);
      expect(result.code, 'I1');
      await cubit.close();
    });
  });

  group('mutations rethrow on error', () {
    test('updateHealth rethrows', () async {
      final fakes = _Fakes();
      fakes.updateHealth.error = Exception('update failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateHealth(studentCode: 'S1', request: _request()),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });

    test('updateImmunization rethrows', () async {
      final fakes = _Fakes();
      fakes.updateImmunization.error = Exception('update failed');
      final cubit = fakes.build();

      await expectLater(
        cubit.updateImmunization(
          studentCode: 'S1',
          record: _immunization('I1'),
          date: DateTime(2026, 1, 1),
          status: 'DUE',
        ),
        throwsA(isA<Exception>()),
      );
      await cubit.close();
    });
  });

  test(
    'single-flight: two concurrent updateHealth for the same student issue '
    'ONE use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<StudentHealth>();
      fakes.updateHealth.gate = gate;
      final cubit = fakes.build();

      final f1 = cubit.updateHealth(studentCode: 'S1', request: _request());
      final f2 = cubit.updateHealth(studentCode: 'S1', request: _request());

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.updateHealth.calls, 1);

      gate.complete(_health());
      await Future.wait<StudentHealth>([f1, f2]);

      expect(fakes.updateHealth.calls, 1);
      await cubit.close();
    },
  );

  test(
    'single-flight: two concurrent updateImmunization for the same record '
    'issue ONE use-case call and share the identical future',
    () async {
      final fakes = _Fakes();
      final gate = Completer<StudentImmunization>();
      fakes.updateImmunization.gate = gate;
      final cubit = fakes.build();

      final record = _immunization('I1');
      final f1 = cubit.updateImmunization(
        studentCode: 'S1',
        record: record,
        date: DateTime(2026, 1, 1),
        status: 'DUE',
      );
      final f2 = cubit.updateImmunization(
        studentCode: 'S1',
        record: record,
        date: DateTime(2026, 1, 1),
        status: 'DUE',
      );

      expect(identical(f1, f2), isTrue);

      await Future<void>.delayed(Duration.zero);
      expect(fakes.updateImmunization.calls, 1);

      gate.complete(_immunization('I1'));
      await Future.wait<StudentImmunization>([f1, f2]);

      expect(fakes.updateImmunization.calls, 1);
      await cubit.close();
    },
  );
}
