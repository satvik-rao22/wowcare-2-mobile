import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Marks a saved payment method as the auto-pay method
/// (`PUT /payment-gateway/payment-methods/{code}/autopay`).
class SetAutopayMethodUseCase {
  SetAutopayMethodUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<PaymentMethodEntity> call({
    required String paymentMethodCode,
    required GuardianScopeParams scope,
  }) =>
      _repository.setAutopayMethod(
        paymentMethodCode: paymentMethodCode,
        scope: scope,
      );
}
