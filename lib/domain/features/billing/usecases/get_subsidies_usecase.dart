import '../entities/invoice_catalog_entities.dart';
import '../repositories/invoice_catalog_repository.dart';

class GetSubsidiesUseCase {
  GetSubsidiesUseCase(this._repository);

  final InvoiceCatalogRepository _repository;

  Future<List<SubsidyEntity>> call({
    required String school,
    String? status,
  }) =>
      _repository.getSubsidies(school: school, status: status);
}
