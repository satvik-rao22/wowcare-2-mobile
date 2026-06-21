import 'dart:typed_data';

import 'package:wowcare/data/features/billing/datasources/billing_statements_remote_datasource.dart';
import 'package:wowcare/domain/features/billing/entities/billing_statement_entity.dart';
import 'package:wowcare/domain/features/billing/repositories/billing_statements_repository.dart';

class BillingStatementsRepositoryImpl implements BillingStatementsRepository {
  BillingStatementsRepositoryImpl(this._dataSource);

  final BillingStatementsRemoteDataSource _dataSource;

  @override
  Future<List<BillingStatementEntity>> getStatements({
    required String subscriberCode,
  }) async {
    final models =
        await _dataSource.getStatements(subscriberCode: subscriberCode);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Uint8List> downloadStatement({
    required String statementCode,
  }) =>
      _dataSource.downloadStatement(statementCode: statementCode);

  @override
  Future<BillingStatementEntity> generateStatement({
    required String organizationCode,
    required String schoolCode,
    required String ownerType,
    required String subscriberCode,
    required String statementType,
    required DateTime periodStart,
    required DateTime periodEnd,
    required bool includeDescription,
  }) async {
    final model = await _dataSource.generateStatement(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      ownerType: ownerType,
      subscriberCode: subscriberCode,
      statementType: statementType,
      periodStart: periodStart,
      periodEnd: periodEnd,
      includeDescription: includeDescription,
    );
    return model.toEntity();
  }
}
