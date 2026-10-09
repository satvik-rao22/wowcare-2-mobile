import 'package:wowcare/core/observability/app_events.dart';

import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class CreateInvoiceUseCase {
  CreateInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceResultEntity> call(CreateInvoiceParams params) =>
      AppEvents.track(
        AppEvent.billingInvoiceCreate,
        () => _repository.createInvoice(params),
      );
}
