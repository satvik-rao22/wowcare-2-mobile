import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class CreateInvoiceUseCase {
  CreateInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceResultEntity> call(CreateInvoiceParams params) =>
      _repository.createInvoice(params);
}
