import 'package:wowcare/core/observability/app_events.dart';

import '../entities/ledger_entity.dart';
import '../repositories/ledger_repository.dart';

class CreateLedgerUseCase {
  CreateLedgerUseCase(this._repository);

  final LedgerRepository _repository;

  Future<LedgerEntity> call(CreateLedgerParams params) => AppEvents.track(
    AppEvent.billingLedgerCreate,
    () => _repository.createLedger(params),
  );
}
