import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/presentation/features/app_update/view_model/app_update_cubit.dart';

import 'app_update_test_support.dart';

void main() {
  test('shows nothing before the first check lands', () {
    final AppUpdateCubit cubit = cubitOver(FakeAppUpdateRepository());
    expect(cubit.state.showsOptional, isFalse);
    expect(cubit.state.showsRequired, isFalse);
  });

  test('applies the cached rule, then the fresh one', () async {
    final FakeAppUpdateRepository repo = FakeAppUpdateRepository(
      cachedPolicy: optionalFor25,
      freshPolicy: requiredFor25,
    );
    final AppUpdateCubit cubit = cubitOver(repo);
    final List<AppUpdateState> seen = <AppUpdateState>[];
    final sub = cubit.stream.listen(seen.add);

    await cubit.check();
    // Stream events land a microtask after the emit.
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen.map((AppUpdateState s) => s.showsOptional), <bool>[
      true,
      false,
    ]);
    expect(cubit.state.showsRequired, isTrue);
    expect(repo.refreshes, 1);
  });

  test('a failing check changes nothing and never blocks', () async {
    final FakeAppUpdateRepository repo = FakeAppUpdateRepository()
      ..throwOnPolicy = true;
    final AppUpdateCubit cubit = cubitOver(repo);
    await cubit.check();
    expect(cubit.state, const AppUpdateState());
  });

  test('overlapping rechecks share one fetch', () async {
    final FakeAppUpdateRepository repo = FakeAppUpdateRepository();
    final AppUpdateCubit cubit = cubitOver(repo);
    await Future.wait(<Future<void>>[cubit.recheck(), cubit.recheck()]);
    expect(repo.refreshes, 1);
  });

  test('Not now hides the banner and records the dismissed build', () async {
    final FakeAppUpdateRepository repo = FakeAppUpdateRepository(
      cachedPolicy: optionalFor25,
    );
    final AppUpdateCubit cubit = cubitOver(repo);
    await cubit.check();
    expect(cubit.state.showsOptional, isTrue);

    await cubit.dismissOptional();

    expect(cubit.state.showsOptional, isFalse);
    expect(repo.dismissedBuilds, <int>[26]);
  });

  test('a required update cannot be dismissed', () async {
    final FakeAppUpdateRepository repo = FakeAppUpdateRepository(
      cachedPolicy: requiredFor25,
    );
    final AppUpdateCubit cubit = cubitOver(repo);
    await cubit.check();

    await cubit.dismissOptional();

    expect(cubit.state.showsRequired, isTrue);
    expect(repo.dismissedBuilds, isEmpty);
  });

  test(
    'a required update still shows after an optional one was dismissed',
    () async {
      final FakeAppUpdateRepository repo = FakeAppUpdateRepository(
        cachedPolicy: optionalFor25,
      );
      final AppUpdateCubit cubit = cubitOver(repo);
      await cubit.check();
      await cubit.dismissOptional();

      repo.freshPolicy = requiredFor25;
      await cubit.recheck();

      expect(cubit.state.showsRequired, isTrue);
    },
  );

  test('opens the policy URL and flags a store that would not open', () async {
    final FakeAppUpdateRepository repo = FakeAppUpdateRepository(
      cachedPolicy: const AppUpdatePolicy(
        minimumBuild: 26,
        latestBuild: 26,
        storeUrl: 'https://apps.apple.com/app/id1',
      ),
      opens: false,
    );
    final AppUpdateCubit cubit = cubitOver(repo);
    await cubit.check();

    await cubit.openStore();
    expect(repo.openedUrls, <String?>['https://apps.apple.com/app/id1']);
    expect(cubit.state.storeUnavailable, isTrue);

    repo.opens = true;
    await cubit.openStore();
    expect(cubit.state.storeUnavailable, isFalse);
  });
}
