import '../repositories/ledger_repository.dart';

class DeactivateLedgerUseCase {
  DeactivateLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<void> call(String ledgerCode) =>
      _repository.deactivateLedger(ledgerCode);
}
