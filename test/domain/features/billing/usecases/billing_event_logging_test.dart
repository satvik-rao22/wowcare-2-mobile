import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/billing/entities/auto_pay_entity.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_transaction_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/auto_pay_repository.dart';
import 'package:wowcare/domain/features/billing/repositories/discount_repository.dart';
import 'package:wowcare/domain/features/billing/repositories/invoice_repository.dart';
import 'package:wowcare/domain/features/billing/repositories/ledger_repository.dart';
import 'package:wowcare/domain/features/billing/repositories/ledger_transaction_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/add_ledger_transaction_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/deactivate_ledger_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_discount_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/resend_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/set_autopay_status_usecase.dart';

class _FakeAutoPayRepository implements AutoPayRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(
    const AutoPayStatusEntity(guardianCode: 'GRD-1', autopayEnabled: true),
  );
}

/// Every call completes with nothing, or fails with [error] when set.
mixin _Scripted {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      error == null ? Future<void>.value() : Future<Never>.error(error!);
}

class _FakeDiscountRepository with _Scripted implements DiscountRepository {}

class _FakeLedgerRepository with _Scripted implements LedgerRepository {}

class _FakeLedgerTransactionRepository
    with _Scripted
    implements LedgerTransactionRepository {}

class _FakeInvoiceRepository with _Scripted implements InvoiceRepository {}

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

  test(
    'discount, ledger and transaction writes log their outcome only',
    () async {
      await DeleteDiscountUseCase(_FakeDiscountRepository())('DSC-1');
      await DeactivateLedgerUseCase(_FakeLedgerRepository())('LDG-1');
      await AddLedgerTransactionUseCase(_FakeLedgerTransactionRepository())(
        const AddTransactionParams(
          ledgerCode: 'LDG-1',
          amount: 125.5,
          date: '2026-10-12',
          narration: 'Tuition adjustment',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(logs.map((log) => log.body), [
        'billing.discount_delete.succeeded',
        'billing.ledger_deactivate.succeeded',
        'billing.ledger_transaction_add.succeeded',
      ]);
      expect(logs.every((log) => log.attributes['count'] == null), isTrue);
      _expectNothingFrom(logs, [
        'DSC-1',
        'LDG-1',
        '125.5',
        '2026-10-12',
        'Tuition adjustment',
      ]);
    },
  );

  test('a resend failure is bucketed and rethrown untouched', () async {
    final request = RequestOptions(path: '/invoices/INV-1/resend');
    final error = DioException.badResponse(
      statusCode: 404,
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 404),
    );
    final repository = _FakeInvoiceRepository()..error = error;

    await expectLater(
      ResendInvoiceUseCase(repository)('INV-1'),
      throwsA(same(error)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(logs.single.body, 'billing.invoice_resend.failed');
    expect(logs.single.attributes['failure']!.value, 'notFound');
    _expectNothingFrom(logs, ['INV-1', '/invoices']);
  });
}

/// Fails when any identifier or amount passed in appears in a logged line.
void _expectNothingFrom(List<SentryLog> logs, List<String> passedIn) {
  final logged = [
    for (final log in logs) ...[
      log.body,
      for (final attribute in log.attributes.values) '${attribute.value}',
    ],
  ].join(' ');
  for (final value in passedIn) {
    expect(logged, isNot(contains(value)));
  }
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
