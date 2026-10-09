import 'package:wowcare/core/observability/app_events.dart';

import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class CreateRefundUseCase {
  CreateRefundUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoicePaymentResultEntity> call(InvoicePaymentParams params) =>
      AppEvents.track(
        AppEvent.billingRefund,
        () => _repository.createRefund(params),
      );
}
