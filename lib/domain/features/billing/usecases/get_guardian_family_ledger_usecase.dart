import '../entities/family_ledger_entity.dart';
import '../repositories/invoice_repository.dart';

class GetGuardianFamilyLedgerUseCase {
  GetGuardianFamilyLedgerUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<FamilyLedgerEntity> call({
    required String organizationCode,
    required String school,
    required String guardianCode,
  }) =>
      _repository.getGuardianFamilyLedger(
        organizationCode: organizationCode,
        school: school,
        guardianCode: guardianCode,
      );
}
