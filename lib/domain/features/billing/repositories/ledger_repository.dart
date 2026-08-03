import '../entities/ledger_entity.dart';

abstract class LedgerRepository {
  Future<LedgerPageEntity> getLedgers({
    required String organizationCode,
    required String school,
    String? search,
    String? category,
    String? status,
    int page = 0,
    int size = 50,
  });

  Future<LedgerEntity> createLedger(CreateLedgerParams params);

  Future<LedgerEntity> getLedgerByCode(String ledgerCode);

  Future<void> deleteLedger(String ledgerCode);

  Future<LedgerEntity> updateLedger({
    required String ledgerCode,
    required CreateLedgerParams params,
  });

  Future<void> deactivateLedger(String ledgerCode);
  Future<void> reactivateLedger(String ledgerCode);
}
