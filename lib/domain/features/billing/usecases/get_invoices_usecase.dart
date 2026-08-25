import '../entities/invoice_list_entity.dart';
import '../repositories/invoice_repository.dart';

/// Fetches one page of invoices for the Transactions tab
/// (`GET /api/v1/invoices/{organizationCode}`).
class GetInvoicesUseCase {
  GetInvoicesUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<PaginatedInvoicesEntity> call({
    required String organizationCode,
    required String school,
    int page = 0,
    int size = 20,
    String? search,
    String? status,
    String? invoiceStatus,
  }) => _repository.listInvoices(
    organizationCode: organizationCode,
    school: school,
    page: page,
    size: size,
    search: search,
    status: status,
    invoiceStatus: invoiceStatus,
  );
}
