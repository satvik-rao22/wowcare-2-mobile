import '../entities/family_summary_entity.dart';
import '../repositories/invoice_repository.dart';

class GetFamilySummaryUseCase {
  GetFamilySummaryUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<List<FamilySummaryEntity>> call({
    required String organizationCode,
    required String school,
  }) =>
      _repository.getFamilySummary(
        organizationCode: organizationCode,
        school: school,
      );
}
