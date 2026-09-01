import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/staff/entities/staff_important_date.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_important_dates_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_important_dates_usecase.dart';
import 'package:wowcare/presentation/features/staff/cubit/important_dates_cubit.dart';

/// Unused by these tests — [ImportantDatesCubit.warmSchoolTimezone] is never
/// called here — but required by the constructor. `noSuchMethod` throws if
/// that ever changes without this fake being updated.
class _FakeStorageService implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Hand-written fake standing in for both the plain [StaffRepository] contract
/// and its cache-aware [StaffRepositoryWithCache] side, so the cubit's
/// cache-first read and its update both exercise real use cases over
/// controllable data. Everything else throws via [noSuchMethod].
class _FakeRepo implements StaffRepository, StaffRepositoryWithCache {
  /// Value returned from [loadCachedImportantDates] (null = cache miss).
  List<StaffImportantDate>? cached;

  /// Value returned from [getImportantDates] (the API read).
  List<StaffImportantDate> apiDates = const [];

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
  Future<List<StaffImportantDate>?> loadCachedImportantDates(
    String staffCode,
  ) async {
    cacheCalls++;
    return cached;
  }

  @override
  Future<List<StaffImportantDate>> getImportantDates({
    required String staffCode,
  }) async {
    getCalls++;
    if (getError != null) throw getError!;
    return apiDates;
  }

  @override
  Future<String> updateImportantDates({
    required String staffCode,
    required List<StaffImportantDate> dates,
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
  storageService: _FakeStorageService(),
  apiClient: _FakeApiClient(),
);

void main() {
  group('fetchImportantDates', () {
    test('returns the cached list without hitting the API when useCache and a '
        'cached value exists', () async {
      final repo = _FakeRepo()
        ..cached = [
          StaffImportantDate(
            importantDateType: 'HIRE_DATE',
            dueDate: '2026-01-01',
          ),
        ]
        ..apiDates = [
          StaffImportantDate(importantDateType: 'CDA', dueDate: '2026-09-09'),
        ];
      final cubit = _cubit(repo);

      final result = await cubit.fetchImportantDates('S1');

      expect(result, repo.cached);
      expect(repo.cacheCalls, 1);
      expect(repo.getCalls, 0);
      await cubit.close();
    });

    test('falls through to the API use case on a cache miss', () async {
      final repo = _FakeRepo()
        ..cached = null
        ..apiDates = [
          StaffImportantDate(importantDateType: 'CDA', dueDate: '2026-02-02'),
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
          StaffImportantDate(
            importantDateType: 'HIRE_DATE',
            dueDate: '2026-01-01',
          ),
        ]
        ..apiDates = [
          StaffImportantDate(importantDateType: 'BRC', dueDate: '2026-03-03'),
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

      await cubit.updateImportantDates(
        staffCode: 'S1',
        dates: const [StaffImportantDate(importantDateType: '', dueDate: '')],
      );

      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.message, 'Saved!');
      expect(repo.updateCalls, 1);
      await cubit.close();
    });

    test('emits an error state when the update fails', () async {
      final repo = _FakeRepo()..updateError = Exception('nope');
      final cubit = _cubit(repo);

      await cubit.updateImportantDates(
        staffCode: 'S1',
        dates: const [StaffImportantDate(importantDateType: '', dueDate: '')],
      );

      expect(cubit.state.isError, isTrue);
      expect(cubit.state.isSuccess, isFalse);
      await cubit.close();
    });

    test('two rapid update calls issue exactly ONE underlying use-case call '
        '(single-flight guard)', () async {
      final repo = _FakeRepo()..updateGate = Completer<String>();
      final cubit = _cubit(repo);

      // Two rapid taps while the first is still in flight.
      final f1 = cubit.updateImportantDates(
        staffCode: 'S1',
        dates: const [StaffImportantDate(importantDateType: '', dueDate: '')],
      );
      final f2 = cubit.updateImportantDates(
        staffCode: 'S1',
        dates: const [StaffImportantDate(importantDateType: '', dueDate: '')],
      );

      await Future<void>.delayed(Duration.zero);

      // The second call is dropped by the _inFlight guard.
      expect(repo.updateCalls, 1);

      repo.updateGate!.complete('done');
      await Future.wait<void>([f1, f2]);

      expect(repo.updateCalls, 1);
      expect(cubit.state.isSuccess, isTrue);
      await cubit.close();
    });

    test(
      'an update whose response lands after the cubit is closed does NOT emit '
      '(isClosed guard — no emit-after-close StateError)',
      () async {
        final repo = _FakeRepo()..updateGate = Completer<String>();
        final cubit = _cubit(repo);

        // Start the update (emits loading, then parks on the in-flight gate).
        final pending = cubit.updateImportantDates(
          staffCode: 'S1',
          dates: const [StaffImportantDate(importantDateType: '', dueDate: '')],
        );
        await Future<void>.delayed(Duration.zero);

        // Tear the cubit down while the update is still in flight, then let the
        // response resolve. Without the post-await isClosed guard the success
        // fold would emit on a closed cubit and throw.
        await cubit.close();
        repo.updateGate!.complete('done');

        await expectLater(pending, completes);
        expect(cubit.isClosed, isTrue);
      },
    );
  });
}
