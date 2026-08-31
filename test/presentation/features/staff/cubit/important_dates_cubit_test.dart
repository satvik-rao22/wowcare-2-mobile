import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_important_dates_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_important_dates_usecase.dart';
import 'package:wowcare/presentation/features/staff/cubit/important_dates_cubit.dart';

/// Hand-written fake standing in for both the plain [StaffRepository] contract
/// and its cache-aware [StaffRepositoryWithCache] side, so the cubit's
/// cache-first read and its update both exercise real use cases over
/// controllable data. Everything else throws via [noSuchMethod].
class _FakeRepo implements StaffRepository, StaffRepositoryWithCache {
  /// Value returned from [loadCachedImportantDates] (null = cache miss).
  List<Map<String, String>>? cached;

  /// Value returned from [getImportantDates] (the API read).
  List<Map<String, String>> apiDates = const [];

  /// When set, [getImportantDates] throws this (use case folds it to a Left).
  Object? getError;

  int cacheCalls = 0;
  int getCalls = 0;

  // --- update controls ---
  int updateCalls = 0;
  String updateResult = 'updated';
  Object? updateError;

  /// When set, [updateImportantDates] blocks on this gate so two rapid calls
  /// overlap in flight (single-flight assertion).
  Completer<String>? updateGate;

  @override
  Future<List<Map<String, String>>?> loadCachedImportantDates(
    String staffCode,
  ) async {
    cacheCalls++;
    return cached;
  }

  @override
  Future<List<Map<String, String>>> getImportantDates({
    required String staffCode,
  }) async {
    getCalls++;
    if (getError != null) throw getError!;
    return apiDates;
  }

  @override
  Future<String> updateImportantDates({
    required String staffCode,
    required List<Map<String, String>> dates,
  }) {
    updateCalls++;
    if (updateGate != null) return updateGate!.future;
    if (updateError != null) return Future<String>.error(updateError!);
    return Future<String>.value(updateResult);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

ImportantDatesCubit _cubit(_FakeRepo repo) => ImportantDatesCubit(
  getImportantDatesUseCase: GetImportantDatesUseCase(repo),
  updateImportantDatesUseCase: UpdateImportantDatesUseCase(repo),
  staffRepository: repo,
);

void main() {
  group('fetchImportantDates', () {
    test(
      'returns the cached list without hitting the API when useCache and a '
      'cached value exists',
      () async {
        final repo = _FakeRepo()
          ..cached = [
            {'importantDateType': 'HIRE_DATE', 'dueDate': '2026-01-01'},
          ]
          ..apiDates = [
            {'importantDateType': 'CDA', 'dueDate': '2026-09-09'},
          ];
        final cubit = _cubit(repo);

        final result = await cubit.fetchImportantDates('S1');

        expect(result, repo.cached);
        expect(repo.cacheCalls, 1);
        expect(repo.getCalls, 0);
        await cubit.close();
      },
    );

    test('falls through to the API use case on a cache miss', () async {
      final repo = _FakeRepo()
        ..cached = null
        ..apiDates = [
          {'importantDateType': 'CDA', 'dueDate': '2026-02-02'},
        ];
      final cubit = _cubit(repo);

      final result = await cubit.fetchImportantDates('S1');

      expect(result, repo.apiDates);
      expect(repo.cacheCalls, 1);
      expect(repo.getCalls, 1);
      await cubit.close();
    });

    test('skips the cache entirely when useCache is false', () async {
      final repo = _FakeRepo()
        ..cached = [
          {'importantDateType': 'HIRE_DATE', 'dueDate': '2026-01-01'},
        ]
        ..apiDates = [
          {'importantDateType': 'BRC', 'dueDate': '2026-03-03'},
        ];
      final cubit = _cubit(repo);

      final result = await cubit.fetchImportantDates('S1', useCache: false);

      expect(result, repo.apiDates);
      expect(repo.cacheCalls, 0);
      expect(repo.getCalls, 1);
      await cubit.close();
    });

    test('throws the Failure when the API read fails', () async {
      final repo = _FakeRepo()
        ..cached = null
        ..getError = Exception('boom');
      final cubit = _cubit(repo);

      await expectLater(
        cubit.fetchImportantDates('S1'),
        throwsA(isA<Failure>()),
      );
      await cubit.close();
    });
  });

  group('updateImportantDates', () {
    test('emits a success state carrying the API message', () async {
      final repo = _FakeRepo()..updateResult = 'Saved!';
      final cubit = _cubit(repo);

      await cubit.updateImportantDates(staffCode: 'S1', dates: const [{}]);

      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.message, 'Saved!');
      expect(repo.updateCalls, 1);
      await cubit.close();
    });

    test('emits an error state when the update fails', () async {
      final repo = _FakeRepo()..updateError = Exception('nope');
      final cubit = _cubit(repo);

      await cubit.updateImportantDates(staffCode: 'S1', dates: const [{}]);

      expect(cubit.state.isError, isTrue);
      expect(cubit.state.isSuccess, isFalse);
      await cubit.close();
    });

    test(
      'two rapid update calls issue exactly ONE underlying use-case call '
      '(single-flight guard)',
      () async {
        final repo = _FakeRepo()..updateGate = Completer<String>();
        final cubit = _cubit(repo);

        // Two rapid taps while the first is still in flight.
        final f1 = cubit.updateImportantDates(
          staffCode: 'S1',
          dates: const [{}],
        );
        final f2 = cubit.updateImportantDates(
          staffCode: 'S1',
          dates: const [{}],
        );

        await Future<void>.delayed(Duration.zero);

        // The second call is dropped by the _inFlight guard.
        expect(repo.updateCalls, 1);

        repo.updateGate!.complete('done');
        await Future.wait<void>([f1, f2]);

        expect(repo.updateCalls, 1);
        expect(cubit.state.isSuccess, isTrue);
        await cubit.close();
      },
    );
  });
}
