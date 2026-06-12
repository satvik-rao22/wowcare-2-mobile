import '../repositories/ledger_repository.dart';

class ReactivateLedgerUseCase {
  ReactivateLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<void> call(String ledgerCode) =>
      _repository.reactivateLedger(ledgerCode);
}
