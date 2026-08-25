import 'package:wowcare/data/features/billing/datasources/ledger_remote_datasource.dart';
import 'package:wowcare/data/features/billing/models/ledger_models.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/ledger_repository.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  LedgerRepositoryImpl(this._dataSource);

  final LedgerRemoteDataSource _dataSource;

  @override
  Future<LedgerPageEntity> getLedgers({
    required String organizationCode,
    required String school,
    String? search,
    String? category,
    String? status,
    int page = 0,
    int size = 50,
  }) async {
    final model = await _dataSource.getLedgers(
      organizationCode: organizationCode,
      school: school,
      search: search,
      category: category,
      status: status,
      page: page,
      size: size,
    );
    return _mapPage(model);
  }

  @override
  Future<LedgerEntity> createLedger(CreateLedgerParams params) async {
    final model = await _dataSource.createLedger(_toRequest(params));
    return _mapModel(model);
  }

  @override
  Future<LedgerEntity> getLedgerByCode(String ledgerCode) async {
    final model = await _dataSource.getLedgerByCode(ledgerCode);
    return _mapModel(model);
  }

  @override
  Future<void> deleteLedger(String ledgerCode) =>
      _dataSource.deleteLedger(ledgerCode);

  @override
  Future<LedgerEntity> updateLedger({
    required String ledgerCode,
    required CreateLedgerParams params,
  }) async {
    final model = await _dataSource.updateLedger(
      ledgerCode: ledgerCode,
      request: _toRequest(params),
    );
    return _mapModel(model);
  }

  @override
  Future<void> deactivateLedger(String ledgerCode) =>
      _dataSource.deactivateLedger(ledgerCode);

  @override
  Future<void> reactivateLedger(String ledgerCode) =>
      _dataSource.reactivateLedger(ledgerCode);

  // — Mappers ———————————————————————————————————————————————————————————

  LedgerEntity _mapModel(LedgerModel m) => LedgerEntity(
    code: m.code,
    name: m.name,
    description: m.description,
    ledgerType: m.ledgerType,
    category: m.category,
    nature: m.nature,
    currency: m.currency,
    status: m.status,
    system: m.system,
    openingBalance: m.openingBalance,
    openingBalanceType: m.openingBalanceType,
    currentBalance: m.currentBalance,
    balanceType: m.balanceType,
  );

  LedgerPageEntity _mapPage(LedgerPageModel p) => LedgerPageEntity(
    content: p.content.map(_mapModel).toList(),
    totalPages: p.totalPages,
    totalElements: p.totalElements,
    number: p.number,
    last: p.last,
  );

  LedgerRequestModel _toRequest(CreateLedgerParams p) => LedgerRequestModel(
    name: p.name,
    code: p.code,
    organization: p.organization,
    school: p.school,
    ledgerType: p.ledgerType,
    description: p.description,
    category: p.category,
    currency: p.currency,
    openingBalanceType: p.openingBalanceType,
    openingBalance: p.openingBalance,
    allowManualBalance: p.allowManualBalance,
  );
}
