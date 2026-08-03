import '../entities/invoice_analytics_entity.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceAnalyticsUseCase {
  GetInvoiceAnalyticsUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<InvoiceAnalyticsEntity> call({
    required String organizationCode,
    required String school,
    int? year,
  }) =>
      _repository.getAnalytics(
        organizationCode: organizationCode,
        school: school,
        year: year,
      );
}
