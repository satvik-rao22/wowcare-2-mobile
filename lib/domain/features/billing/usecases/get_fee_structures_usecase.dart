import '../entities/invoice_catalog_entities.dart';
import '../repositories/invoice_catalog_repository.dart';

class GetFeeStructuresUseCase {
  GetFeeStructuresUseCase(this._repository);

  final InvoiceCatalogRepository _repository;

  Future<List<FeeStructureEntity>> call({
    required String school,
    String? status,
  }) => _repository.getFeeStructures(school: school, status: status);
}
