import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class ResendInvoiceUseCase {
  ResendInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceResultEntity> call(String code) =>
      _repository.resendInvoice(code);
}
