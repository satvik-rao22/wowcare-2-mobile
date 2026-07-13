import '../entities/billing_statement_entity.dart';
import '../repositories/billing_statements_repository.dart';

class GetBillingStatementsUseCase {
  GetBillingStatementsUseCase(this._repository);

  final BillingStatementsRepository _repository;

  Future<List<BillingStatementEntity>> call({
    required String subscriberCode,
  }) =>
      _repository.getStatements(subscriberCode: subscriberCode);
}
