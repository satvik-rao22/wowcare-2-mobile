import 'dart:typed_data';

import '../entities/billing_statement_entity.dart';

abstract class BillingStatementsRepository {
  Future<List<BillingStatementEntity>> getStatements({
    required String subscriberCode,
  });

  Future<Uint8List> downloadStatement({required String statementCode});

  Future<BillingStatementEntity> generateStatement({
    required String organizationCode,
    required String schoolCode,
    required String ownerType,
    required String subscriberCode,
    required String statementType,
    required DateTime periodStart,
    required DateTime periodEnd,
    required bool includeDescription,
  });
}
