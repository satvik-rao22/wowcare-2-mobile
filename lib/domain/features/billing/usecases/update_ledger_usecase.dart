import 'package:wowcare/core/observability/app_events.dart';

import '../entities/ledger_entity.dart';
import '../repositories/ledger_repository.dart';

class UpdateLedgerUseCase {
  UpdateLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<LedgerEntity> call({
    required String ledgerCode,
    required CreateLedgerParams params,
  }) => AppEvents.track(
    AppEvent.billingLedgerUpdate,
    () => _repository.updateLedger(ledgerCode: ledgerCode, params: params),
  );
}
