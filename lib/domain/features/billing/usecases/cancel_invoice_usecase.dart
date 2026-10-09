import 'package:wowcare/core/observability/app_events.dart';

import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class CancelInvoiceUseCase {
  CancelInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceResultEntity> call(String code) => AppEvents.track(
    AppEvent.billingInvoiceCancel,
    () => _repository.cancelInvoice(code),
  );
}
