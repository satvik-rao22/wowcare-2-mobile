import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/ledger_repository.dart';

class DeleteLedgerUseCase {
  DeleteLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<void> call(String ledgerCode) => AppEvents.track(
    AppEvent.billingLedgerDelete,
    () => _repository.deleteLedger(ledgerCode),
  );
}
