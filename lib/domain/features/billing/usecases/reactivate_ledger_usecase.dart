import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/ledger_repository.dart';

class ReactivateLedgerUseCase {
  ReactivateLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<void> call(String ledgerCode) => AppEvents.track(
    AppEvent.billingLedgerReactivate,
    () => _repository.reactivateLedger(ledgerCode),
  );
}
