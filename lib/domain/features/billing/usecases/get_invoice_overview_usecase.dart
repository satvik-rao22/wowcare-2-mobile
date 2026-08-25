import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceOverviewUseCase {
  GetInvoiceOverviewUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceOverviewEntity> call({
    required String organizationCode,
    required String school,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) => _repository.getOverview(
    organizationCode: organizationCode,
    school: school,
    dateFrom: dateFrom,
    dateTo: dateTo,
  );
}
