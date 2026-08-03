import '../entities/ledger_entity.dart';
import '../repositories/ledger_repository.dart';

class GetLedgerByCodeUseCase {
  GetLedgerByCodeUseCase(this._repository);

  final LedgerRepository _repository;

  Future<LedgerEntity> call(String ledgerCode) =>
      _repository.getLedgerByCode(ledgerCode);
}
