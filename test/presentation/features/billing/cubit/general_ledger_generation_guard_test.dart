import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/ledger_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/deactivate_ledger_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_ledger_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_ledgers_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/reactivate_ledger_usecase.dart';
import 'package:wowcare/presentation/features/billing/cubit/general_ledger_cubit.dart';

/// A ledger repository whose `getLedgers` hands back a fresh [Completer] per
/// call, so a test can resolve responses out of order (a slow older page
/// landing after a fast newer one) and assert the generation guard discards
/// the stale result.
class _FakeLedgerRepo implements LedgerRepository {
  final List<Completer<LedgerPageEntity>> gates = <Completer<LedgerPageEntity>>[];

  int get callCount => gates.length;

  @override
  Future<LedgerPageEntity> getLedgers({
    required String organizationCode,
    required String school,
    String? search,
    String? category,
    String? status,
    int page = 0,
    int size = 50,
  }) {
    final c = Completer<LedgerPageEntity>();
    gates.add(c);
    return c.future;
  }

  void complete(int call, LedgerPageEntity page) => gates[call].complete(page);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// In-memory storage: real school/org codes, cache reads always miss, cache
/// writes are no-ops (so the cubit's cache path never touches disk).
class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async {
    if (key == StorageKeys.schoolCode) return 'SCH-1';
    if (key == StorageKeys.organizationCode) return 'ORG-1';
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async => null;

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async {}

  @override
  Future<Set<String>> getKeys() async => <String>{};

  @override
  Future<void> remove(String key) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

GeneralLedgerCubit _build(_FakeLedgerRepo repo) => GeneralLedgerCubit(
      getLedgersUseCase: GetLedgersUseCase(repo),
      deleteLedgerUseCase: DeleteLedgerUseCase(repo),
      deactivateLedgerUseCase: DeactivateLedgerUseCase(repo),
      reactivateLedgerUseCase: ReactivateLedgerUseCase(repo),
      storageService: _FakeStorage(),
    );

LedgerPageEntity _page(
  List<String> codes, {
  required int number,
  required bool last,
}) =>
    LedgerPageEntity(
      content: [
        for (final c in codes) LedgerEntity(code: c, name: 'name-$c'),
      ],
      totalPages: 1,
      totalElements: codes.length,
      number: number,
      last: last,
    );

/// Pumps the event loop until [cond] holds (or fails after a bounded number of
/// turns). Each turn drains pending microtasks and timers.
Future<void> _pumpUntil(bool Function() cond) async {
  for (var i = 0; i < 200; i++) {
    if (cond()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('condition not met after pumping');
}

void main() {
  test(
      'a slow older load whose response lands after a newer refresh is discarded '
      '(the newer result wins)', () async {
    final repo = _FakeLedgerRepo();
    final cubit = _build(repo);

    // Start the (slow) initial load — gen 1, registers call 0.
    final f1 = cubit.loadInitial();
    await _pumpUntil(() => repo.callCount >= 1);

    // A refresh supersedes it — gen 2, registers call 1.
    final f2 = cubit.refresh();
    await _pumpUntil(() => repo.callCount >= 2);

    // The NEWER refresh resolves FIRST and wins.
    repo.complete(1, _page(['B'], number: 0, last: true));
    await f2;
    expect(cubit.state.allLedgers.map((e) => e.id), ['B']);

    // The OLDER load resolves LAST — it must be DISCARDED, not clobber ['B'].
    repo.complete(0, _page(['A'], number: 0, last: true));
    await f1;
    expect(cubit.state.allLedgers.map((e) => e.id), ['B'],
        reason: 'stale older response must not overwrite the newer one');

    await cubit.close();
  });

  test('overlapping pages collapse by stable id; id-less rows are kept',
      () async {
    final repo = _FakeLedgerRepo();
    final cubit = _build(repo);

    // Page 0 (reset): A, B — more available.
    final f1 = cubit.loadInitial();
    await _pumpUntil(() => repo.callCount >= 1);
    repo.complete(0, _page(['A', 'B'], number: 0, last: false));
    await f1;
    expect(cubit.state.allLedgers.map((e) => e.id), ['A', 'B']);

    // Page 1 (append): B repeats (dup), C is new, and one id-less row.
    final f2 = cubit.loadNextPage();
    await _pumpUntil(() => repo.callCount >= 2);
    repo.complete(1, _page(['B', 'C', ''], number: 1, last: true));
    await f2;

    // B collapses to the first occurrence; C appended; the id-less row kept.
    expect(cubit.state.allLedgers.map((e) => e.id), ['A', 'B', 'C', '']);

    await cubit.close();
  });
}
