import '../entities/invoice_list_entity.dart';
import '../repositories/invoice_repository.dart';

/// Fetches a single invoice's full detail (incl. line items) for the edit form
/// (`GET /api/v1/invoices/by-code/{code}`).
class GetInvoiceByCodeUseCase {
  GetInvoiceByCodeUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceListItemEntity> call(String code) =>
      _repository.getInvoiceByCode(code);
}
