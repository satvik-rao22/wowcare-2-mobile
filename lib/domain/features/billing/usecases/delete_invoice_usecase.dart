import '../repositories/invoice_repository.dart';

class DeleteInvoiceUseCase {
  DeleteInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<void> call(String code) => _repository.deleteInvoice(code);
}
