import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

/// Fetches one page of the Transactions list for an org/school + date range.
class GetInvoiceTransactionsUseCase {
  GetInvoiceTransactionsUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceTransactionsPage> call({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    String? status,
    int page = 0,
    int size = 10,
  }) => _repository.getTransactions(
    organizationCode: organizationCode,
    school: school,
    dateFrom: dateFrom,
    dateTo: dateTo,
    type: type,
    status: status,
    page: page,
    size: size,
  );
}
