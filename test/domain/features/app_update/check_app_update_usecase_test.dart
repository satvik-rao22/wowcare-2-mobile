import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';
import 'package:wowcare/domain/features/app_update/entities/app_version.dart';
import 'package:wowcare/domain/features/app_update/repositories/app_update_repository.dart';
import 'package:wowcare/domain/features/app_update/usecases/check_app_update_usecase.dart';
import 'package:wowcare/domain/features/app_update/usecases/dismiss_optional_update_usecase.dart';

class _FakeRepository implements AppUpdateRepository {
  _FakeRepository({required this.installedBuild, required this.policy});

  int installedBuild;
  AppUpdatePolicy policy;
  ({int latestBuild, DateTime at})? dismissal;
  final List<bool> policyReads = <bool>[];

  @override
  StorePlatform get store => StorePlatform.playStore;

  @override
  Future<AppVersion> getInstalledVersion() async =>
      AppVersion(name: '2.2.21', build: installedBuild);

  @override
  Future<AppUpdatePolicy> getPolicy({required bool refresh}) async {
    policyReads.add(refresh);
    return policy;
  }

  @override
  Future<DateTime?> optionalDismissedAt({required int latestBuild}) async =>
      dismissal?.latestBuild == latestBuild ? dismissal!.at : null;

  @override
  Future<void> saveOptionalDismissal({
    required int latestBuild,
    required DateTime at,
  }) async => dismissal = (latestBuild: latestBuild, at: at);

  @override
  Future<bool> openStore(String? url) async => true;
}

void main() {
  final DateTime now = DateTime(2026, 9, 28, 9, 41);

  AppUpdatePolicy rule({required int minimum, required int latest}) =>
      AppUpdatePolicy(minimumBuild: minimum, latestBuild: latest);

  group('AppUpdatePolicy.requirementFor', () {
    test('below the minimum is required', () {
      expect(
        rule(minimum: 25, latest: 30).requirementFor(24),
        AppUpdateRequirement.required,
      );
    });

    test('at the minimum but below the latest is optional', () {
      expect(
        rule(minimum: 25, latest: 30).requirementFor(25),
        AppUpdateRequirement.optional,
      );
    });

    test('at or past the latest is up to date', () {
      expect(
        rule(minimum: 25, latest: 30).requirementFor(30),
        AppUpdateRequirement.none,
      );
      expect(
        rule(minimum: 25, latest: 30).requirementFor(31),
        AppUpdateRequirement.none,
      );
    });

    test('an unreadable installed build never blocks', () {
      expect(
        rule(minimum: 25, latest: 30).requirementFor(0),
        AppUpdateRequirement.none,
      );
    });

    test('the none policy asks nothing of any build', () {
      expect(AppUpdatePolicy.none.requirementFor(1), AppUpdateRequirement.none);
    });
  });

  group('CheckAppUpdateUseCase', () {
    test(
      'reports the requirement with the installed version and store',
      () async {
        final _FakeRepository repo = _FakeRepository(
          installedBuild: 20,
          policy: rule(minimum: 25, latest: 30),
        );
        final AppUpdateStatus status = await CheckAppUpdateUseCase(repo)();
        expect(status.isRequired, isTrue);
        expect(status.installed, const AppVersion(name: '2.2.21', build: 20));
        expect(status.store, StorePlatform.playStore);
      },
    );

    test('passes refresh through to the policy read', () async {
      final _FakeRepository repo = _FakeRepository(
        installedBuild: 30,
        policy: rule(minimum: 25, latest: 30),
      );
      final CheckAppUpdateUseCase check = CheckAppUpdateUseCase(repo);
      await check();
      await check(refresh: true);
      expect(repo.policyReads, <bool>[false, true]);
    });

    test('an optional update dismissed within the week stays quiet', () async {
      final _FakeRepository repo = _FakeRepository(
        installedBuild: 26,
        policy: rule(minimum: 25, latest: 30),
      );
      await DismissOptionalUpdateUseCase(
        repo,
        clock: () => now.subtract(const Duration(days: 6, hours: 23)),
      )(latestBuild: 30);
      final AppUpdateStatus status = await CheckAppUpdateUseCase(
        repo,
        clock: () => now,
      )();
      expect(status.requirement, AppUpdateRequirement.none);
    });

    test('it comes back once the week is up', () async {
      final _FakeRepository repo =
          _FakeRepository(
              installedBuild: 26,
              policy: rule(minimum: 25, latest: 30),
            )
            ..dismissal = (
              latestBuild: 30,
              at: now.subtract(const Duration(days: 7)),
            );
      final AppUpdateStatus status = await CheckAppUpdateUseCase(
        repo,
        clock: () => now,
      )();
      expect(status.isOptional, isTrue);
    });

    test('a newer build is a new offer, whatever was dismissed', () async {
      final _FakeRepository repo = _FakeRepository(
        installedBuild: 26,
        policy: rule(minimum: 25, latest: 31),
      )..dismissal = (latestBuild: 30, at: now);
      final AppUpdateStatus status = await CheckAppUpdateUseCase(
        repo,
        clock: () => now,
      )();
      expect(status.isOptional, isTrue);
    });

    test('a required update ignores any dismissal', () async {
      final _FakeRepository repo = _FakeRepository(
        installedBuild: 20,
        policy: rule(minimum: 25, latest: 30),
      )..dismissal = (latestBuild: 30, at: now);
      final AppUpdateStatus status = await CheckAppUpdateUseCase(
        repo,
        clock: () => now,
      )();
      expect(status.isRequired, isTrue);
    });
  });
}
