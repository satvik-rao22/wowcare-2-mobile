import 'package:wowcare/data/features/billing/datasources/ledger_transaction_remote_datasource.dart';
import 'package:wowcare/data/features/billing/models/ledger_transaction_models.dart';
import 'package:wowcare/domain/features/billing/entities/ledger_transaction_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/ledger_transaction_repository.dart';

class LedgerTransactionRepositoryImpl implements LedgerTransactionRepository {
  LedgerTransactionRepositoryImpl(this._dataSource);

  final LedgerTransactionRemoteDataSource _dataSource;

  @override
  Future<LedgerTransactionPageEntity> getTransactions({
    required String ledgerCode,
    String? from,
    String? to,
    int page = 0,
    int size = 10,
  }) async {
    final model = await _dataSource.getTransactions(
      ledgerCode: ledgerCode,
      from: from,
      to: to,
      page: page,
      size: size,
    );
    return _mapPage(model);
  }

  @override
  Future<void> addTransaction(AddTransactionParams params) =>
      _dataSource.addTransaction(
        AddTransactionRequestModel(
          ledgerCode: params.ledgerCode,
          amount: params.amount,
          date: params.date,
          narration: params.narration,
          direction: params.direction,
        ),
      );

  LedgerTransactionEntity _mapModel(LedgerTransactionModel m) =>
      LedgerTransactionEntity(
        code: m.code,
        type: m.type,
        description: m.description,
        contraAccount: m.contraAccount,
        debit: m.debit,
        credit: m.credit,
        balance: m.balance,
        balanceType: m.balanceType,
        date: m.date,
      );

  LedgerTransactionPageEntity _mapPage(LedgerTransactionPageModel p) =>
      LedgerTransactionPageEntity(
        content: p.content.map(_mapModel).toList(),
        totalPages: p.totalPages,
        totalElements: p.totalElements,
        size: p.size,
        number: p.number,
        numberOfElements: p.numberOfElements,
        last: p.last,
      );
}
