import '../entities/ledger_entity.dart';
import '../repositories/ledger_repository.dart';

class UpdateLedgerUseCase {
  UpdateLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<LedgerEntity> call({
    required String ledgerCode,
    required CreateLedgerParams params,
  }) => _repository.updateLedger(ledgerCode: ledgerCode, params: params);
}
