import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class CancelInvoiceUseCase {
  CancelInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceResultEntity> call(String code) =>
      _repository.cancelInvoice(code);
}
