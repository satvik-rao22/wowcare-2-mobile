import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/invoice_repository.dart';

class DeleteInvoiceUseCase {
  DeleteInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<void> call(String code) => AppEvents.track(
    AppEvent.billingInvoiceDelete,
    () => _repository.deleteInvoice(code),
  );
}
