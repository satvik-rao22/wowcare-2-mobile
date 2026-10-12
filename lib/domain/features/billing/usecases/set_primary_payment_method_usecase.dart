import 'package:wowcare/core/observability/app_events.dart';

import '../entities/auto_pay_entity.dart';
import '../repositories/auto_pay_repository.dart';

/// Marks a saved payment method as primary / the auto-pay method
/// (`PUT /payment-gateway/payment-methods/{code}/primary`).
class SetPrimaryPaymentMethodUseCase {
  SetPrimaryPaymentMethodUseCase(this._repository);

  final AutoPayRepository _repository;

  Future<PaymentMethodEntity> call({
    required String paymentMethodCode,
    required GuardianScopeParams scope,
  }) => AppEvents.track(
    AppEvent.billingPaymentMethodSetPrimary,
    () => _repository.setPrimaryPaymentMethod(
      paymentMethodCode: paymentMethodCode,
      scope: scope,
    ),
  );
}
