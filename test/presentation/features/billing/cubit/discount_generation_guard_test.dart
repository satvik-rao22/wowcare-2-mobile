import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/discount_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/discount_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/deactivate_discount_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_discount_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_discounts_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/reactivate_discount_usecase.dart';
import 'package:wowcare/presentation/features/billing/cubit/discount_cubit.dart';

/// A discount repository handing back a fresh [Completer] per `getDiscounts`
/// call so responses can be resolved out of order.
class _FakeDiscountRepo implements DiscountRepository {
  final List<Completer<DiscountPageEntity>> gates =
      <Completer<DiscountPageEntity>>[];

  int get callCount => gates.length;

  @override
  Future<DiscountPageEntity> getDiscounts({
    required String school,
    String? name,
    String? status,
    int page = 0,
    int size = 50,
  }) {
    final c = Completer<DiscountPageEntity>();
    gates.add(c);
    return c.future;
  }

  void complete(int call, DiscountPageEntity page) => gates[call].complete(page);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async =>
      key == StorageKeys.schoolCode ? 'SCH-1' : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

DiscountCubit _build(_FakeDiscountRepo repo) => DiscountCubit(
      getDiscountsUseCase: GetDiscountsUseCase(repo),
      deleteDiscountUseCase: DeleteDiscountUseCase(repo),
      deactivateDiscountUseCase: DeactivateDiscountUseCase(repo),
      reactivateDiscountUseCase: ReactivateDiscountUseCase(repo),
      storageService: _FakeStorage(),
    );

DiscountPageEntity _page(
  List<String> codes, {
  required int number,
  required bool last,
}) =>
    DiscountPageEntity(
      content: [
        for (final c in codes) DiscountEntity(code: c, name: 'name-$c'),
      ],
      totalPages: 1,
      totalElements: codes.length,
      number: number,
      last: last,
    );

Future<void> _pumpUntil(bool Function() cond) async {
  for (var i = 0; i < 200; i++) {
    if (cond()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('condition not met after pumping');
}

void main() {
  test('a stale first-page load landing after a newer one is discarded',
      () async {
    final repo = _FakeDiscountRepo();
    final cubit = _build(repo);

    // First (slow) load — gen 1, call 0.
    final f1 = cubit.loadInitial();
    await _pumpUntil(() => repo.callCount >= 1);

    // setStatusFilter routes through a fresh loadInitial — gen 2, call 1.
    cubit.setStatusFilter('INACTIVE');
    await _pumpUntil(() => repo.callCount >= 2);

    // Newer filter resolves first and wins.
    repo.complete(1, _page(['B'], number: 0, last: true));
    await _pumpUntil(() => cubit.state.allDiscounts.isNotEmpty);
    expect(cubit.state.allDiscounts.map((e) => e.code), ['B']);

    // Older load resolves last — discarded.
    repo.complete(0, _page(['A'], number: 0, last: true));
    await f1;
    expect(cubit.state.allDiscounts.map((e) => e.code), ['B'],
        reason: 'stale older response must not overwrite the newer one');

    await cubit.close();
  });

  test('overlapping pages collapse by code; code-less rows kept', () async {
    final repo = _FakeDiscountRepo();
    final cubit = _build(repo);

    final f1 = cubit.loadInitial();
    await _pumpUntil(() => repo.callCount >= 1);
    repo.complete(0, _page(['A', 'B'], number: 0, last: false));
    await f1;
    expect(cubit.state.allDiscounts.map((e) => e.code), ['A', 'B']);

    final f2 = cubit.loadNextPage();
    await _pumpUntil(() => repo.callCount >= 2);
    repo.complete(1, _page(['B', 'C', ''], number: 1, last: true));
    await f2;
    expect(cubit.state.allDiscounts.map((e) => e.code), ['A', 'B', 'C', '']);

    await cubit.close();
  });
}
