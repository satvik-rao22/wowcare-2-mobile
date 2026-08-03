import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Removes a saved payment method
/// (`DELETE /payment-gateway/payment-methods/{code}`).
class DeletePaymentMethodUseCase {
  DeletePaymentMethodUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<void> call({
    required String paymentMethodCode,
    required GuardianScopeParams scope,
  }) =>
      _repository.deletePaymentMethod(
        paymentMethodCode: paymentMethodCode,
        scope: scope,
      );
}
