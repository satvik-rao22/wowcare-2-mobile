import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/auto_pay_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/set_autopay_status_usecase.dart';

class _FakeAutoPayRepository implements AutoPayRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(
    const AutoPayStatusEntity(guardianCode: 'GRD-1', autopayEnabled: true),
  );
}

void main() {
  final logs = <SentryLog>[];

  setUp(() async {
    logs.clear();
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

  test(
    'autopay logs enable or disable, and nothing about the guardian',
    () async {
      const scope = GuardianScopeParams(
        organizationCode: 'ORG-1',
        schoolCode: 'SCH-1',
        guardianCode: 'GRD-1',
      );
      final useCase = SetAutoPayStatusUseCase(_FakeAutoPayRepository());

      await useCase(scope: scope, autopayEnabled: true);
      await useCase(scope: scope, autopayEnabled: false);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(logs.map((log) => log.body), [
        'billing.autopay_enable.succeeded',
        'billing.autopay_disable.succeeded',
      ]);
      for (final log in logs) {
        expect(
          log.attributes.values.map((a) => '${a.value}'),
          isNot(contains(anyOf('GRD-1', 'SCH-1', 'ORG-1'))),
        );
      }
    },
  );
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
