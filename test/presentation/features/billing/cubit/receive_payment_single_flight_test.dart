import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/invoice_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/create_payment_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/create_refund_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_family_ledger_usecase.dart';
import 'package:wowcare/presentation/features/billing/cubit/receive_payment_refund_cubit.dart';

const _okResult = InvoicePaymentResultEntity();

class _FakeRepo implements InvoiceRepository {
  final List<InvoicePaymentParams> payments = <InvoicePaymentParams>[];
  Completer<InvoicePaymentResultEntity>? gate;
  Object? throwError;

  @override
  Future<InvoicePaymentResultEntity> createPayment(
      InvoicePaymentParams params) {
    payments.add(params);
    if (throwError != null) return Future.error(throwError!);
    if (gate != null) return gate!.future;
    return Future.value(_okResult);
  }

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

ReceivePaymentRefundCubit _build(_FakeRepo repo) => ReceivePaymentRefundCubit(
      createPayment: CreatePaymentUseCase(repo),
      createRefund: CreateRefundUseCase(repo),
      getFamilyLedger: GetFamilyLedgerUseCase(repo),
      storage: _FakeStorage(),
    )..setPaymentType('Cash');

void main() {
  test('two concurrent validateAndSave fire ONE underlying payment (single-flight)',
      () async {
    final repo = _FakeRepo()..gate = Completer<InvoicePaymentResultEntity>();
    final cubit = _build(repo);

    final f1 = cubit.validateAndSave(
        amount: '100', chequeNumber: '', isRefund: false, studentCode: 'STU-1');
    final f2 = cubit.validateAndSave(
        amount: '100', chequeNumber: '', isRefund: false, studentCode: 'STU-1');

    await Future<void>.delayed(Duration.zero);
    expect(repo.payments.length, 1); // only one create dispatched

    repo.gate!.complete(_okResult);
    expect(await f1, ReceivePaymentRefundResult.success);
    expect(await f2, ReceivePaymentRefundResult.success);

    await cubit.close();
  });

  test('a retry after failure reuses the SAME idempotency key', () async {
    final repo = _FakeRepo()..throwError = Exception('timeout');
    final cubit = _build(repo);

    final r1 = await cubit.validateAndSave(
        amount: '100', chequeNumber: '', isRefund: false, studentCode: 'STU-1');
    expect(r1, ReceivePaymentRefundResult.failure);

    // Retry the same operation — key must be stable so the backend dedupes.
    final r2 = await cubit.validateAndSave(
        amount: '100', chequeNumber: '', isRefund: false, studentCode: 'STU-1');
    expect(r2, ReceivePaymentRefundResult.failure);

    expect(repo.payments.length, 2);
    expect(repo.payments[0].idempotencyKey, isNotNull);
    expect(repo.payments[0].idempotencyKey, repo.payments[1].idempotencyKey);

    await cubit.close();
  });

  test('after success the key rotates — a later payment gets a fresh key',
      () async {
    final repo = _FakeRepo();
    final cubit = _build(repo);

    await cubit.validateAndSave(
        amount: '100', chequeNumber: '', isRefund: false, studentCode: 'STU-1');
    await cubit.validateAndSave(
        amount: '100', chequeNumber: '', isRefund: false, studentCode: 'STU-1');

    expect(repo.payments.length, 2);
    expect(repo.payments[0].idempotencyKey,
        isNot(repo.payments[1].idempotencyKey));

    await cubit.close();
  });
}
