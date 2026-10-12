import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/repositories/app_update_repository.dart';
import 'package:wowcare/domain/features/app_update/usecases/dismiss_optional_update_usecase.dart';
import 'package:wowcare/domain/features/app_update/usecases/open_app_store_usecase.dart';

/// Opens the store when [storeOpens], and records every dismissal.
class _FakeAppUpdateRepository implements AppUpdateRepository {
  bool storeOpens = true;
  final dismissedBuilds = <int>[];

  @override
  Future<bool> openStore(String? url) async => storeOpens;

  @override
  Future<void> saveOptionalDismissal({
    required int latestBuild,
    required DateTime at,
  }) async => dismissedBuilds.add(latestBuild);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  final logs = <SentryLog>[];
  late _FakeAppUpdateRepository repository;

  setUp(() async {
    logs.clear();
    repository = _FakeAppUpdateRepository();
    await Sentry.init((options) {
      options
        ..dsn = 'https://key@o1.ingest.sentry.io/1'
        ..enableLogs = true
        ..transport = _DiscardingTransport()
        ..beforeSendLog = (log) {
          logs.add(log);
          return log;
        };
    });
  });

  tearDown(() => Sentry.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  const policy = AppUpdatePolicy(
    minimumBuild: 10,
    latestBuild: 4242,
    storeUrl: 'https://apps.apple.com/app/id6760719887',
  );

  test('a dismissal logs its outcome, not the build', () async {
    await DismissOptionalUpdateUseCase(repository)(latestBuild: 4242);
    await settle();

    expect(repository.dismissedBuilds, [4242]);
    expect(logs.single.body, 'app.update_dismiss.succeeded');
    expect(
      logs.single.attributes.values.map((a) => '${a.value}'),
      isNot(contains('4242')),
    );
  });

  test('a store that will not open is an unavailable failure', () async {
    final useCase = OpenAppStoreUseCase(repository);

    expect(await useCase(policy), isTrue);
    repository.storeOpens = false;
    expect(await useCase(policy), isFalse);
    await settle();

    expect(logs.map((log) => log.body), [
      'app.store_open.succeeded',
      'app.store_open.failed',
    ]);
    expect(logs.last.attributes['failure']!.value, 'unavailable');
    for (final log in logs) {
      expect(
        log.attributes.values.map((a) => '${a.value}'),
        isNot(contains(contains('apple.com'))),
      );
    }
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
