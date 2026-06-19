import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Lists the guardian's saved payment methods
/// (`GET /payment-gateway/payment-methods`).
class GetPaymentMethodsUseCase {
  GetPaymentMethodsUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<List<PaymentMethodEntity>> call(GuardianScopeParams params) =>
      _repository.getPaymentMethods(params);
}
