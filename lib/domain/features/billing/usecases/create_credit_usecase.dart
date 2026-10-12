import 'package:wowcare/core/observability/app_events.dart';

import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

/// Adds account credit for a family/owner (`POST /api/v1/invoices/credits`).
class CreateCreditUseCase {
  CreateCreditUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoicePaymentResultEntity> call(CreateCreditParams params) =>
      AppEvents.track(
        AppEvent.billingCreditCreate,
        () => _repository.createCredit(params),
      );
}
