import '../entities/invoice_catalog_entities.dart';
import '../repositories/invoice_catalog_repository.dart';

class GetOtherFeesUseCase {
  GetOtherFeesUseCase(this._repository);

  final InvoiceCatalogRepository _repository;

  Future<List<OtherFeeEntity>> call({
    required String school,
    String? status,
  }) =>
      _repository.getOtherFees(school: school, status: status);
}
