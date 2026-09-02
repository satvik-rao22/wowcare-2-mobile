import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/invoice_repository.dart';
import 'package:wowcare/domain/features/billing/usecases/cancel_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/delete_invoice_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_overview_usecase.dart';
import 'package:wowcare/domain/features/billing/usecases/get_invoice_transactions_usecase.dart';
import 'package:wowcare/presentation/features/billing/cubit/transactions_cubit.dart';

InvoiceTransactionEntity _row(String id) => InvoiceTransactionEntity(
      id: id,
      type: 'PAYMENT',
      date: DateTime.utc(2026, 1, 1),
      familyCode: 'F',
      familyName: 'Fam',
      studentCode: 'S',
      studentName: 'Stu',
      description: 'd',
      status: 'PAID',
      method: 'Cash',
      amount: 10,
      paidAmount: 10,
      refundedAmount: 0,
      invoiceCode: '', // deliberately empty — the OLD dedup key
    );

class _FakeRepo implements InvoiceRepository {
  final Map<int, InvoiceTransactionsPage> pages;
  _FakeRepo(this.pages);

  @override
  Future<InvoiceTransactionsPage> getTransactions({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    String? status,
    int page = 0,
    int size = 10,
  }) async =>
      pages[page] ??
      (items: const <InvoiceTransactionEntity>[], hasMore: false, totalElements: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async {
    if (key == StorageKeys.organizationCode) return 'ORG-1';
    if (key == StorageKeys.schoolCode) return 'SCH-1';
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  test(
    'load-more dedups by the stable transaction id and KEEPS rows with no id '
    '(the old invoiceCode dedup silently dropped them)',
    () async {
      final repo = _FakeRepo({
        0: (
          items: [_row('T1'), _row(''), _row('T2')], // one id-less row
          hasMore: true,
          totalElements: 6
        ),
        1: (
          items: [_row('T2'), _row(''), _row('T3')], // T2 dup + another id-less
          hasMore: false,
          totalElements: 6
        ),
      });
      final cubit = TransactionsCubit(
        getOverview: GetInvoiceOverviewUseCase(repo),
        getTransactions: GetInvoiceTransactionsUseCase(repo),
        cancelInvoice: CancelInvoiceUseCase(repo),
        deleteInvoice: DeleteInvoiceUseCase(repo),
        storage: _FakeStorage(),
      );

      await cubit.loadTransactions();
      expect(cubit.state.transactions.length, 3);

      await cubit.loadNextPage();

      final ids = cubit.state.transactions.map((r) => r.item.transactionId);
      // T2 deduped to one; BOTH id-less rows kept → 3 + (idless + T3) = 5.
      expect(cubit.state.transactions.length, 5);
      expect(ids.where((id) => id == 'T2').length, 1);
      expect(ids.where((id) => id == null).length, 2); // no id-less row dropped

      await cubit.close();
    },
  );
}
