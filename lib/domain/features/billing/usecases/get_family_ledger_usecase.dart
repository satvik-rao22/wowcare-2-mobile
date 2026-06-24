import '../entities/family_ledger_entity.dart';
import '../repositories/invoice_repository.dart';

/// Fetches a family's billing ledger (`GET /api/v1/invoices/family-ledger`)
/// for the billing profile screen.
class GetFamilyLedgerUseCase {
  GetFamilyLedgerUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<FamilyLedgerEntity> call({
    required String organizationCode,
    required String school,
    required String ownerCode,
    String ownerType = 'FAMILY',
  }) =>
      _repository.getFamilyLedger(
        organizationCode: organizationCode,
        school: school,
        ownerType: ownerType,
        ownerCode: ownerCode,
      );
}
