import '../entities/ledger_entity.dart';
import '../repositories/ledger_repository.dart';

class CreateLedgerUseCase {
  CreateLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<LedgerEntity> call(CreateLedgerParams params) =>
      _repository.createLedger(params);
}
