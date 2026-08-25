import '../entities/ledger_transaction_entity.dart';
import '../repositories/ledger_transaction_repository.dart';

class GetLedgerTransactionsUseCase {
  GetLedgerTransactionsUseCase(this._repository);

  final LedgerTransactionRepository _repository;

  Future<LedgerTransactionPageEntity> call({
    required String ledgerCode,
    String? from,
    String? to,
    int page = 0,
    int size = 10,
  }) => _repository.getTransactions(
    ledgerCode: ledgerCode,
    from: from,
    to: to,
    page: page,
    size: size,
  );
}
