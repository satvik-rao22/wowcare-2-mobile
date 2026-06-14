import '../repositories/ledger_repository.dart';

class DeleteLedgerUseCase {
  DeleteLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<void> call(String ledgerCode) => _repository.deleteLedger(ledgerCode);
}
