import '../entities/ledger_transaction_entity.dart';

abstract class LedgerTransactionRepository {
  Future<LedgerTransactionPageEntity> getTransactions({
    required String ledgerCode,
    String? from,
    String? to,
    int page = 0,
    int size = 10,
  });

  Future<void> addTransaction(AddTransactionParams params);
}
