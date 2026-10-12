import 'package:wowcare/core/observability/app_events.dart';

import '../entities/ledger_transaction_entity.dart';
import '../repositories/ledger_transaction_repository.dart';

class AddLedgerTransactionUseCase {
  AddLedgerTransactionUseCase(this._repository);

  final LedgerTransactionRepository _repository;

  Future<void> call(AddTransactionParams params) => AppEvents.track(
    AppEvent.billingLedgerTransactionAdd,
    () => _repository.addTransaction(params),
  );
}
