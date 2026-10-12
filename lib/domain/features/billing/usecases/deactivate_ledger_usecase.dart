import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/ledger_repository.dart';

class DeactivateLedgerUseCase {
  DeactivateLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<void> call(String ledgerCode) => AppEvents.track(
    AppEvent.billingLedgerDeactivate,
    () => _repository.deactivateLedger(ledgerCode),
  );
}
